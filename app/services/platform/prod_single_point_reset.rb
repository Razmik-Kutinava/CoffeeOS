# frozen_string_literal: true

module Platform
  # Финальный сброс прода к одной точке: на боевой точке остаётся только владелец (глобальный УК),
  # демо-смены и все сотрудники удаляются, тестовые точки (кроме цехов боевой точки) и тест-гости — тоже,
  # ключи витрины отзываются. Банковские платежи боевой точки не трогаются.
  # Всё в одной транзакции; dry_run — те же шаги + ROLLBACK.
  class ProdSinglePointReset
    UK_ROLE = "ук_global_admin"
    TEST_CUSTOMER_EMAIL_PATTERNS = %w[%@coffeeos.dev %@demo.coffeeos.local %@example.com %@example.org mcp%].freeze
    TEST_CUSTOMER_NAMES = %w[MCP MT B112 V461 BR6 E2E Expanded WorkerCallbackSmoke Stage52Smoke].freeze
    TEST_CUSTOMER_NAME_PREFIXES = %w[ISO-% KIOSK-% SHP10-% B11-%].freeze

    Result = Struct.new(:dry_run, :steps, :verification, keyword_init: true)

    def self.call(owner_email:, dry_run: true, real_tenant_id: ProdDataCleanup::REAL_TENANT_ID, protect_phones: [])
      new(owner_email: owner_email, dry_run: dry_run, real_tenant_id: real_tenant_id,
          protect_phones: protect_phones).call
    end

    def initialize(owner_email:, dry_run:, real_tenant_id:, protect_phones:)
      @owner_email = owner_email.to_s.strip.downcase
      @dry_run = dry_run
      @real_tenant_id = real_tenant_id.to_s
      @protect_phones = Array(protect_phones).map(&:to_s).reject(&:blank?)
      @steps = {}
    end

    def call
      verification = nil
      conn.transaction do
        # Ops-задача работает поверх всех тенантов от владельца БД; RLS здесь только мешает видеть данные.
        conn.execute("SET LOCAL row_security = off")
        raise "Real tenant not found (#{@real_tenant_id})" unless Tenant.exists?(id: @real_tenant_id)

        before = bank_snapshot
        owner = promote_owner!
        reset_shifts!
        delete_staff!(owner)
        delete_other_tenants!
        delete_test_customers!
        revoke_api_keys!

        verification = verify(before, owner)
        raise ActiveRecord::Rollback if @dry_run || !verification[:pass]
      end
      Result.new(dry_run: @dry_run, steps: @steps, verification: verification)
    end

    private

    def conn
      ActiveRecord::Base.connection
    end

    def promote_owner!
      owner = User.where("LOWER(email) = ?", @owner_email).first
      raise "Owner not found (#{@owner_email})" unless owner

      owner.update_columns(tenant_id: @real_tenant_id, status: "active", updated_at: Time.current)
      role = Role.find_by!(code: UK_ROLE)
      unless UserRole.exists?(user_id: owner.id, role_id: role.id, tenant_id: nil)
        # Глобальная роль — tenant_id NULL; ApplicationRecord#ensure_tenant_id в проде запрещает create без тенанта.
        UserRole.insert_all([ { user_id: owner.id, role_id: role.id, tenant_id: nil } ])
      end
      @steps[:owner] = { email: owner.email, roles: owner.user_roles.joins(:role).pluck("roles.code") }
      owner
    end

    # Демо-смены открывал demo barista-a; без них сотрудников можно удалить (FK opened_by — RESTRICT).
    # Витрина от смены не зависит; новую смену откроет настоящий бариста.
    def reset_shifts!
      shift_ids = CashShift.where(tenant_id: @real_tenant_id).pluck(:id)
      @steps[:cash_shifts_deleted] = shift_ids.size
      @steps[:orders_unlinked_from_shift] = Order.where(cash_shift_id: shift_ids).update_all(cash_shift_id: nil)
      CashShift.where(id: shift_ids).delete_all
      Shift.where(tenant_id: @real_tenant_id).delete_all
    end

    def delete_staff!(owner)
      staff = User.where(tenant_id: @real_tenant_id).where.not(id: owner.id)
      @steps[:staff_deleted] = staff.order(:email).pluck(:email)
      counts = ProdPurge.delete_or_block_users!(staff)
      @steps[:staff_blocked_referenced] = counts[:users_blocked]
    end

    def delete_other_tenants!
      keep = [ @real_tenant_id ] + kitchen_ids
      tenants = Tenant.where.not(id: keep).order(:slug)
      @steps[:tenants_deleted] = tenants.pluck(:slug)
      @steps[:tenants_kept] = Tenant.where(id: keep).order(:slug).pluck(:slug)
      @steps[:deleted_bank_payments] = Payment.where(tenant_id: tenants.select(:id))
                                              .where.not(provider_payment_id: nil)
                                              .where(status: %w[succeeded refunded])
                                              .pluck(:provider_payment_id, :amount)
                                              .map { |pid, amount| "#{pid}:#{amount}" }
      counts = ProdPurge.delete_tenants!(tenants.pluck(:id))
      @steps[:users_deleted_with_tenants] = counts[:users_deleted]
      @steps[:users_blocked_with_tenants] = counts[:users_blocked]
    end

    def kitchen_ids
      conn.select_values(
        "SELECT prep_kitchen_tenant_id FROM prep_kitchen_sales_point_links " \
        "WHERE sales_point_tenant_id = #{conn.quote(@real_tenant_id)}"
      )
    end

    def delete_test_customers!
      scope = MobileCustomer.where(ilike_any("mobile_customers.email", TEST_CUSTOMER_EMAIL_PATTERNS))
                            .or(MobileCustomer.where(first_name: TEST_CUSTOMER_NAMES))
                            .or(MobileCustomer.where(ilike_any("mobile_customers.first_name", TEST_CUSTOMER_NAME_PREFIXES)))
      scope = scope.where.not(phone: @protect_phones) if @protect_phones.any?
      ids = scope.pluck(:id)
      @steps[:test_customers_deleted] = ids.size
      @steps[:test_customers_with_paid_orders] = paid_customer_labels(ids)
      ProdPurge.delete_customers!(ids)
    end

    def paid_customer_labels(ids)
      MobileCustomer.where(id: ids)
                    .where(id: Order.joins(:payments).where(payments: { status: %w[succeeded refunded] }).select(:customer_id))
                    .pluck(:first_name, :email, :phone).map { |row| row.compact.join(" ") }
    end

    def revoke_api_keys!
      scope = ShopApiKey.where(tenant_id: @real_tenant_id, active: true)
      @steps[:api_keys_revoked] = scope.pluck(:name)
      now = Time.current
      scope.update_all(active: false, revoked_at: now, updated_at: now)
    end

    def bank_snapshot
      Payment.where(tenant_id: @real_tenant_id).where.not(provider_payment_id: nil).count
    end

    def verify(before, owner)
      checks = {
        real_tenant_active: Tenant.where(id: @real_tenant_id, status: "active").exists?,
        bank_payments_preserved: bank_snapshot == before,
        only_owner_on_tenant: User.where(tenant_id: @real_tenant_id).pluck(:id) == [ owner.id ],
        owner_is_uk: owner.user_roles.joins(:role).where(roles: { code: UK_ROLE }).exists?,
        no_open_shift: !CashShift.where(tenant_id: @real_tenant_id, status: "open").exists?,
        no_active_api_keys: !ShopApiKey.where(tenant_id: @real_tenant_id, active: true).exists?
      }
      checks[:pass] = checks.values.all?
      checks.merge(bank_payments_before: before)
    end

    def ilike_any(column, patterns)
      [ "#{column} ILIKE ANY (ARRAY[?])", patterns ]
    end
  end
end
