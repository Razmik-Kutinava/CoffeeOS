# frozen_string_literal: true

module Shop
  module Api
    class DebugController < Shop::BaseController
      include Shop::Concerns::TenantResolution

      def index
        tid = resolved_shop_tenant_id
        tenant = Tenant.find_by(id: tid)

        all_tenants = Tenant.all.select(:id, :slug, :name, :status).map do |t|
          { id: t.id, slug: t.slug, name: t.name, status: t.status }
        end

        all_products = Product.all.select(:id, :name, :slug, :is_active, :category_id, :base_price).map do |p|
          { id: p.id, name: p.name, slug: p.slug, is_active: p.is_active, category_id: p.category_id, base_price: p.base_price&.to_f }
        end

        all_categories = Category.all.select(:id, :name, :slug, :is_active).map do |c|
          { id: c.id, name: c.name, slug: c.slug, is_active: c.is_active }
        end

        # PTS запрос внутри транзакции с SET LOCAL
        pts_data = []
        if tenant
          ActiveRecord::Base.transaction do
            conn = ActiveRecord::Base.connection
            conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant.id.to_s)}")
            pts_data = ProductTenantSetting.where(tenant_id: tenant.id).map do |pts|
              { product_id: pts.product_id, price: pts.price&.to_f, is_enabled: pts.is_enabled, is_sold_out: pts.is_sold_out }
            end
          end
        end

        render json: {
          resolved_tenant_id: tid,
          resolved_tenant: tenant ? { id: tenant.id, slug: tenant.slug, name: tenant.name } : nil,
          env: {
            SHOP_DEFAULT_TENANT_ID: ENV["SHOP_DEFAULT_TENANT_ID"],
            ORG_SLUG: ENV["ORG_SLUG"],
            RAILS_ENV: Rails.env
          },
          tenants: all_tenants,
          products: all_products,
          categories: all_categories,
          product_tenant_settings_for_tenant: pts_data
        }
      end
    end
  end
end
