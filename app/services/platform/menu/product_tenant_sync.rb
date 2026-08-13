# frozen_string_literal: true

module Platform
  module Menu
    # Синхронизация ProductTenantSetting: товар УК → все точки (витрина / barista).
    module ProductTenantSync
      module_function

      def sync_product_to_all_tenants!(product:, user:)
        raise ArgumentError, "product must be persisted" unless product&.persisted?
        raise ArgumentError, "user required" unless user&.id

        uid = user.id
        fallback = price_fallback(product)
        enabled = product.is_active != false

        Tenant.select(:id).find_each do |tenant|
          upsert_pts!(product: product, tenant_id: tenant.id, user_id: uid, fallback: fallback, enabled: enabled)
        end

        bust_shop_catalog_cache!
        product
      ensure
        Current.tenant_id = nil
      end

      def needs_repair?
        tenant_count = Tenant.count
        return false if tenant_count.zero?

        Product.where(is_active: true)
          .left_joins(:product_tenant_settings)
          .group("products.id")
          .having("COUNT(DISTINCT product_tenant_settings.tenant_id) < ?", tenant_count)
          .exists?
      end

      # Товары без PTS хотя бы на одной точке — дозаполнить (импорт, seed, старые записи).
      def repair_missing_pts!(user:)
        actor = user || fallback_uk_user
        raise ArgumentError, "user required for RLS" unless actor&.id

        tenant_count = Tenant.count
        return if tenant_count.zero?

        ids = Product
          .left_joins(:product_tenant_settings)
          .group("products.id")
          .having("COUNT(DISTINCT product_tenant_settings.tenant_id) < ?", tenant_count)
          .pluck(:id)

        Product.where(id: ids).find_each do |product|
          sync_product_to_all_tenants!(product: product, user: actor)
        end
      end

      def bust_shop_catalog_cache!(tenant_ids: nil)
        ids = tenant_ids.presence || Tenant.pluck(:id)
        Array(ids).each do |tenant_id|
          bust_categories_cache_for!(tenant_id)
        end
      rescue StandardError => e
        Rails.logger.warn("[ProductTenantSync] cache bust skipped: #{e.class}: #{e.message}")
      end

      def bust_categories_cache_for!(tenant_id)
        pages = [ nil, "", *1..5 ]
        per_pages = [ nil, "", "1", "10", "50" ]
        pages.each do |page|
          per_pages.each do |per|
            Rails.cache.delete("shop/categories/#{tenant_id}/#{page}/#{per}")
          end
        end
      end

      def upsert_pts!(product:, tenant_id:, user_id:, fallback:, enabled:)
        ActiveRecord::Base.transaction do
          conn = ActiveRecord::Base.connection
          conn.execute("SET LOCAL app.current_user_id = #{conn.quote(user_id.to_s)}")
          conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant_id.to_s)}")

          Current.tenant_id = tenant_id

          pts = ProductTenantSetting.find_or_initialize_by(tenant_id: tenant_id, product_id: product.id)
          bp = product.base_price.presence&.to_d
          pts.price = (bp.present? && bp.positive?) ? bp : (pts.price.presence || fallback)
          pts.price = fallback if pts.price.blank? || pts.price <= 0
          pts.is_enabled = enabled
          pts.is_sold_out = false if enabled
          pts.sold_out_reason = nil if enabled
          pts.save!
        end
      end

      def price_fallback(product)
        bp = product.base_price.presence&.to_d
        bp = BigDecimal("1") if bp.blank? || bp <= 0
        bp
      end

      def fallback_uk_user
        User.joins(user_roles: :role).where(roles: { code: "ук_global_admin" }).first
      end
    end
  end
end
