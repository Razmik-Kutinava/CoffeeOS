# frozen_string_literal: true

module Platform
  # Чистка прода от демо/тестовых данных. Всё в одной транзакции; dry_run — те же шаги + ROLLBACK,
  # поэтому счётчики точные, а данные не меняются.
  #
  # Неприкосновенно: платежи, дошедшие до банка (provider_payment_id), и их заказы на сохраняемых точках;
  # точки с успешными/возвращёнными банковскими оплатами; точки с глобальными ролями (УК); цеха боевой точки;
  # гости с банковскими заказами или привязанными картами.
  class ProdDataCleanup
    REAL_TENANT_ID = ProdSinglePointCleanup::POINT_A_TENANT_ID
    BOARD_STATUSES = %w[accepted preparing ready].freeze
    TEST_STAFF_EMAIL_PATTERNS = %w[%@prog10.local].freeze
    TEST_CUSTOMER_EMAIL_PATTERNS = %w[%@coffeeos.dev %@example.com %@example.org mcp%].freeze
    TEST_CUSTOMER_NAME_EXACT = %w[MCP MT].freeze
    TEST_CUSTOMER_NAME_PREFIXES = %w[ISO-% KIOSK-% SHP10-%].freeze
    TEST_API_KEY_PATTERNS = %w[mcp-% seed-%].freeze
    TEST_PRODUCT_PATTERNS = %w[W12-%].freeze
    SOURCE = "ops_cleanup"

    Result = Struct.new(:dry_run, :steps, :verification, keyword_init: true)

    def self.call(dry_run: true, real_tenant_id: REAL_TENANT_ID, keep_api_key_ids: nil)
      new(dry_run: dry_run, real_tenant_id: real_tenant_id, keep_api_key_ids: keep_api_key_ids).call
    end

    def initialize(dry_run:, real_tenant_id:, keep_api_key_ids:)
      @dry_run = dry_run
      @real_tenant_id = real_tenant_id.to_s
      @keep_api_key_ids = Array(keep_api_key_ids).map(&:to_s)
      @steps = {}
    end

    def call
      verification = nil
      conn.transaction do
        # Ops-задача работает поверх всех тенантов от владельца БД; RLS здесь только мешает видеть данные.
        conn.execute("SET LOCAL row_security = off")
        raise "Real tenant not found (#{@real_tenant_id})" unless Tenant.exists?(id: @real_tenant_id)

        before = bank_snapshot
        @keep_tenant_ids = resolve_keep_tenant_ids

        close_board_orders!
        delete_tenants!
        delete_unbanked_orders!
        block_test_staff!
        revoke_test_api_keys!
        delete_test_customers!
        deactivate_test_products!
        delete_failed_pushes!

        verification = verify(before)
        raise ActiveRecord::Rollback if @dry_run || !verification[:pass]
      end
      Result.new(dry_run: @dry_run, steps: @steps, verification: verification)
    end

    private

    def conn
      ActiveRecord::Base.connection
    end

    def bank_touched_sql(alias_name = "orders")
      "EXISTS (SELECT 1 FROM payments bp WHERE bp.order_id = #{alias_name}.id AND bp.provider_payment_id IS NOT NULL)"
    end

    def resolve_keep_tenant_ids
      with_money = Payment.where.not(provider_payment_id: nil)
                          .where(status: %w[succeeded refunded]).distinct.pluck(:tenant_id)
      with_global_roles = User.joins(user_roles: :role)
                              .where(roles: { code: User::GLOBAL_ROLE_CODES }).distinct.pluck(:tenant_id)
      kitchens = conn.select_values(
        "SELECT prep_kitchen_tenant_id FROM prep_kitchen_sales_point_links " \
        "WHERE sales_point_tenant_id = #{conn.quote(@real_tenant_id)}"
      )
      ([ @real_tenant_id ] + with_money + with_global_roles + kitchens).compact.map(&:to_s).uniq
    end

    # Старые заказы боевой точки, висящие на табло/ТВ: оплаченные → выдан, неоплаченные → отменён.
    def close_board_orders!
      orders = Order.where(tenant_id: @real_tenant_id, status: BOARD_STATUSES).where(bank_touched_sql)
                    .where("orders.created_at < ?", 1.hour.ago).to_a
      paid_ids = Payment.where(order_id: orders.map(&:id), status: %w[succeeded refunded]).distinct.pluck(:order_id)
      now = Time.current
      issued, cancelled = orders.partition { |o| paid_ids.include?(o.id) }

      log_status!(issued, "issued", now)
      log_status!(cancelled, "cancelled", now)
      Order.where(id: issued.map(&:id)).update_all(status: "issued", issued_at: now, updated_at: now)
      Order.where(id: cancelled.map(&:id)).update_all(
        status: "cancelled", cancel_reason: "Ops cleanup: оплата не прошла", cancel_stage: SOURCE, updated_at: now
      )

      @steps[:board_orders] = {
        issued: issued.map(&:order_number),
        cancelled: cancelled.map(&:order_number)
      }
    end

    def log_status!(orders, status_to, now)
      return if orders.empty?

      OrderStatusLog.insert_all(orders.map do |o|
        { order_id: o.id, status_from: o.status, status_to: status_to, source: SOURCE,
          comment: "ops cleanup 2026-10", created_at: now, updated_at: now }
      end)
    end

    def delete_tenants!
      tenants = Tenant.where.not(id: @keep_tenant_ids).order(:slug).to_a
      ids = tenants.map(&:id)
      @steps[:tenants_deleted] = tenants.map(&:slug)
      @steps[:tenants_kept] = Tenant.where(id: @keep_tenant_ids).order(:slug).pluck(:slug)
      return if ids.empty?

      order_ids = Order.where(tenant_id: ids).pluck(:id)
      delete_order_dependents!(order_ids)
      Subscription.where(purchase_point_id: ids).delete_all
      Subscription.where(payment_id: Payment.where(tenant_id: ids).select(:id)).delete_all
      %w[shop_email_verifications tenant_weekday_schedules order_wallet_passes order_notification_logs].each do |t|
        conn.exec_delete("DELETE FROM #{t} WHERE tenant_id IN (#{quoted(ids)})")
      end
      %w[point_campaign_settings subscription_offer_settings subscription_usage_events].each do |t|
        conn.exec_delete("DELETE FROM #{t} WHERE point_id IN (#{quoted(ids)})")
      end

      CashShift.where(tenant_id: ids).delete_all
      Shift.where(tenant_id: ids).delete_all
      ShiftStaff.where(tenant_id: ids).delete_all
      delete_or_block_users!(User.where(tenant_id: ids))
      Tenant.where(id: ids).delete_all
    end

    # cash_shifts/shifts/shift_staffs ссылаются на users с ON DELETE RESTRICT — такие только блокируем.
    def delete_or_block_users!(users)
      user_ids = users.pluck(:id)
      referenced = (CashShift.where(opened_by_id: user_ids).pluck(:opened_by_id) |
                    Shift.where(opened_by_id: user_ids).pluck(:opened_by_id) |
                    ShiftStaff.where(user_id: user_ids).pluck(:user_id))
      User.where(id: referenced).update_all(status: "blocked", updated_at: Time.current)
      @steps[:users_blocked_referenced] = referenced.size
      @steps[:users_deleted_with_tenants] = User.where(id: user_ids - referenced).delete_all
    end

    # Заказы без единого похода в банк (имитация оплаты, брошенные оформления, ручные/кассовые прогоны).
    # Текущий месяц не трогаем: номер заказа = MAX(sequence за месяц) + 1, удаление дало бы повтор номера.
    def delete_unbanked_orders!
      scope = Order.where(tenant_id: @keep_tenant_ids).where.not(bank_touched_sql)
                   .where("orders.created_at < ?", Time.current.beginning_of_month)
      by_tenant = scope.joins(:tenant).group("tenants.slug").count
      delete_order_dependents!(scope.pluck(:id))
      @steps[:unbanked_orders_deleted] = by_tenant
      scope.delete_all
    end

    def delete_order_dependents!(order_ids)
      return if order_ids.empty?

      Subscription.where(payment_id: Payment.where(order_id: order_ids).select(:id)).delete_all
      %w[order_emails order_notification_logs order_wallet_passes subscription_usage_events].each do |t|
        conn.exec_delete("DELETE FROM #{t} WHERE order_id IN (#{quoted(order_ids)})")
      end
    end

    def block_test_staff!
      scope = User.where(tenant_id: @keep_tenant_ids).where(status: "active")
                  .where(ilike_any("users.email", TEST_STAFF_EMAIL_PATTERNS))
      @steps[:staff_blocked] = scope.order(:email).pluck(:email)
      scope.update_all(status: "blocked", updated_at: Time.current)
    end

    def revoke_test_api_keys!
      keep = @keep_api_key_ids.presence || latest_real_mcp_key_ids
      scope = ShopApiKey.where(tenant_id: @keep_tenant_ids, active: true)
                        .where(ilike_any("shop_api_keys.name", TEST_API_KEY_PATTERNS))
                        .where.not(id: keep)
      @steps[:api_keys_revoked] = scope.joins(:tenant).pluck("tenants.slug", :name).map { |s, n| "#{s}:#{n}" }
      @steps[:api_keys_kept] = ShopApiKey.where(id: keep).pluck(:name)
      now = Time.current
      scope.update_all(active: false, revoked_at: now, updated_at: now)
    end

    # Пока нет отдельной тестовой точки — оставляем последний использованный mcp-ключ боевой точки.
    def latest_real_mcp_key_ids
      ShopApiKey.where(tenant_id: @real_tenant_id, active: true).where("name ILIKE 'mcp-%'")
                .where.not(last_used_at: nil).order(last_used_at: :desc).limit(1).pluck(:id)
    end

    def delete_test_customers!
      names = MobileCustomer.where(first_name: TEST_CUSTOMER_NAME_EXACT)
                            .or(MobileCustomer.where(ilike_any("mobile_customers.first_name", TEST_CUSTOMER_NAME_PREFIXES)))
      scope = MobileCustomer.where(ilike_any("mobile_customers.email", TEST_CUSTOMER_EMAIL_PATTERNS)).or(names)
      protected_ids = Order.where.not(customer_id: nil).where(bank_touched_sql).distinct.pluck(:customer_id) |
                      MobilePaymentMethod.distinct.pluck(:customer_id)
      ids = scope.where.not(id: protected_ids).pluck(:id)
      @steps[:test_customers_deleted] = ids.size
      @steps[:test_customers_protected] = scope.where(id: protected_ids).count
      return if ids.empty?

      Subscription.where(customer_id: ids).delete_all
      SubscriptionOfferState.where(customer_id: ids).delete_all
      MarketingEvent.where(customer_id: ids).delete_all
      MobileCustomer.where(id: ids).delete_all
    end

    def deactivate_test_products!
      scope = Product.where(is_active: true).where(ilike_any("products.name", TEST_PRODUCT_PATTERNS))
      @steps[:products_deactivated] = scope.pluck(:name)
      scope.update_all(is_active: false, updated_at: Time.current)
    end

    def delete_failed_pushes!
      @steps[:failed_pushes_deleted] = PushNotification.where(status: "failed").delete_all
    end

    def bank_snapshot
      scope = Payment.where(tenant_id: @real_tenant_id).where.not(provider_payment_id: nil)
      { real_bank_payments: scope.count, real_bank_orders: scope.distinct.count(:order_id) }
    end

    def verify(before)
      after = bank_snapshot
      board_left = Order.where(tenant_id: @real_tenant_id, status: BOARD_STATUSES)
                        .where("orders.created_at < ?", 1.hour.ago).count
      checks = {
        real_tenant_active: Tenant.where(id: @real_tenant_id, status: "active").exists?,
        bank_payments_preserved: after == before,
        old_board_orders_left: board_left,
        no_old_board_orders: board_left.zero?
      }
      checks[:pass] = checks[:real_tenant_active] && checks[:bank_payments_preserved] && checks[:no_old_board_orders]
      checks.merge(before: before, after: after)
    end

    def ilike_any(column, patterns)
      [ "#{column} ILIKE ANY (ARRAY[?])", patterns ]
    end

    def quoted(ids)
      ids.map { |id| conn.quote(id.to_s) }.join(",")
    end
  end
end
