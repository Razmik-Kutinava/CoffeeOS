# frozen_string_literal: true

module Shop
  # G-06: session для гостя; session + БД для залогиненного customer (per tenant).
  class FavoritesStore
    BUCKET_KEY = :shop_favorites_by_tenant
    LEGACY_KEY = :shop_favorites

    def self.merge_session_into_db!(session:, tenant_id:, customer_id:)
      new(session: session, tenant: Tenant.find(tenant_id), customer_id: customer_id).merge_session_into_db!
    end

    def initialize(session:, tenant:, customer_id: nil)
      @session = session
      @tenant = tenant
      @customer_id = customer_id.presence
      @tenant_key = tenant.id.to_s
    end

    def product_ids
      ids = session_ids
      return ids if @customer_id.blank?

      db_ids = CustomerFavorite.where(customer_id: @customer_id, tenant_id: @tenant.id).pluck(:product_id).map(&:to_s)
      (db_ids + ids).uniq
    end

    def add!(product_id)
      pid = product_id.to_s
      ids = product_ids
      return if ids.include?(pid)

      write_session!(ids | [ pid ])
      persist_db!(pid) if @customer_id.present?
    end

    def remove!(product_id)
      pid = product_id.to_s
      write_session!(product_ids - [ pid ])
      if @customer_id.present?
        CustomerFavorite.where(customer_id: @customer_id, tenant_id: @tenant.id, product_id: pid).delete_all
      end
    end

    def merge_session_into_db!
      return if @customer_id.blank?

      session_ids.each do |pid|
        CustomerFavorite.find_or_create_by!(customer_id: @customer_id, tenant_id: @tenant.id, product_id: pid)
      end
      write_session!(product_ids)
    end

    private

    def session_ids
      bucket = @session[BUCKET_KEY]
      if bucket.is_a?(Hash) && bucket[@tenant_key].present?
        return Array(bucket[@tenant_key]).map(&:to_s)
      end

      Array(@session[LEGACY_KEY]).map(&:to_s)
    end

    def write_session!(ids)
      bucket = (@session[BUCKET_KEY].is_a?(Hash) ? @session[BUCKET_KEY].dup : {})
      bucket[@tenant_key] = ids
      @session[BUCKET_KEY] = bucket
      @session[LEGACY_KEY] = ids
    end

    def persist_db!(product_id)
      CustomerFavorite.find_or_create_by!(
        customer_id: @customer_id,
        tenant_id: @tenant.id,
        product_id: product_id
      )
    end
  end
end
