# frozen_string_literal: true

module Shop
  # Ожидающий оплату заказ в сессии гостя (один на точку) — идемпотентность «Оплатить».
  class PendingOrderSession
    KEY = :shop_pending_order_by_tenant

    def self.order_id(session, tenant_id)
      bucket = session[KEY]
      return nil unless bucket.is_a?(Hash)

      bucket[tenant_id.to_s].presence
    end

    def self.set!(session, tenant_id, order_id)
      bucket = session[KEY].is_a?(Hash) ? session[KEY].dup : {}
      bucket[tenant_id.to_s] = order_id.to_s
      session[KEY] = bucket
    end

    def self.clear!(session, tenant_id)
      bucket = session[KEY]
      return unless bucket.is_a?(Hash)

      bucket = bucket.dup
      bucket.delete(tenant_id.to_s)
      session[KEY] = bucket
    end
  end
end
