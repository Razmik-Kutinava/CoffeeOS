# frozen_string_literal: true

module Platform
  # Общие операции удаления для ops-чисток прода (ProdDataCleanup, ProdSinglePointReset).
  # Вызывать только внутри транзакции с SET LOCAL row_security = off.
  module ProdPurge
    module_function

    # Удаляет точки целиком: сначала строки с FK без каскада, затем пользователей точки, затем сами точки
    # (заказы/платежи/смены/ключи уходят каскадом). Возвращает { users_deleted:, users_blocked: }.
    def delete_tenants!(ids)
      return { users_deleted: 0, users_blocked: 0 } if ids.empty?

      delete_order_dependents!(Order.where(tenant_id: ids).pluck(:id))
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
      counts = delete_or_block_users!(User.where(tenant_id: ids))
      Tenant.where(id: ids).delete_all
      counts
    end

    # cash_shifts/shifts/shift_staffs ссылаются на users с ON DELETE RESTRICT — такие только блокируем.
    def delete_or_block_users!(users)
      user_ids = users.pluck(:id)
      referenced = CashShift.where(opened_by_id: user_ids).pluck(:opened_by_id) |
                   Shift.where(opened_by_id: user_ids).pluck(:opened_by_id) |
                   ShiftStaff.where(user_id: user_ids).pluck(:user_id)
      User.where(id: referenced).update_all(status: "blocked", updated_at: Time.current)
      { users_deleted: User.where(id: user_ids - referenced).delete_all, users_blocked: referenced.size }
    end

    def delete_order_dependents!(order_ids)
      return if order_ids.empty?

      Subscription.where(payment_id: Payment.where(order_id: order_ids).select(:id)).delete_all
      %w[order_emails order_notification_logs order_wallet_passes subscription_usage_events].each do |t|
        conn.exec_delete("DELETE FROM #{t} WHERE order_id IN (#{quoted(order_ids)})")
      end
    end

    # Заказы гостей не удаляются — customer_id обнуляется (FK on_delete: nullify).
    def delete_customers!(ids)
      return 0 if ids.empty?

      Subscription.where(customer_id: ids).delete_all
      SubscriptionOfferState.where(customer_id: ids).delete_all
      MarketingEvent.where(customer_id: ids).delete_all
      MobileCustomer.where(id: ids).delete_all
    end

    def conn
      ActiveRecord::Base.connection
    end

    def quoted(ids)
      ids.map { |id| conn.quote(id.to_s) }.join(",")
    end
  end
end
