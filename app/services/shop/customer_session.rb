# frozen_string_literal: true

module Shop
  # Привязка гостя витрины к точке: один телефон — разные customer_id на разных tenant_id.
  # Иначе при переключении ?tenant_id= A/B история «пропадает» (фильтр по tenant + customer).
  class CustomerSession
    BUCKET_KEY = :shop_customers_by_tenant
    LEGACY_KEY = :shop_customer_id

    def self.customer_id(session, tenant_id)
      tid = tenant_id.to_s
      bucket = session[BUCKET_KEY]
      if bucket.is_a?(Hash)
        return bucket[tid].to_s if bucket[tid].present?
        # Не подставляем legacy с другой точки — иначе на B «пропадают» заказы после визита A.
        return nil
      end

      session[LEGACY_KEY].presence&.to_s
    end

    def self.set_customer_id!(session, tenant_id, customer_id)
      tid = tenant_id.to_s
      cid = customer_id.to_s
      bucket = (session[BUCKET_KEY].is_a?(Hash) ? session[BUCKET_KEY].dup : {})
      bucket[tid] = cid
      session[BUCKET_KEY] = bucket
      session[LEGACY_KEY] = cid
    end

    def self.clear!(session, tenant_id)
      tid = tenant_id.to_s
      bucket = session[BUCKET_KEY]
      return unless bucket.is_a?(Hash)

      bucket = bucket.dup
      bucket.delete(tid)
      if bucket.empty?
        session.delete(BUCKET_KEY)
        session.delete(LEGACY_KEY)
      else
        session[BUCKET_KEY] = bucket
      end
    end
  end
end
