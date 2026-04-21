# frozen_string_literal: true

module Shop
  module Api
    # Диагностический endpoint для проверки tenant resolution и каталога.
    # Доступен только вне production. В production маршрут не регистрируется (см. routes.rb).
    class DebugController < Shop::Api::BaseController
      def index
        # @shop_tenant и Current.tenant_id установлены через around_action :with_shop_tenant! из BaseController
        tenant = @shop_tenant

        tenant_products = Product
          .joins(:product_tenant_settings)
          .where(product_tenant_settings: { tenant_id: tenant.id })
          .select(:id, :name, :slug, :is_active, :category_id, :base_price)
          .map do |p|
            { id: p.id, name: p.name, slug: p.slug, is_active: p.is_active,
              category_id: p.category_id, base_price: p.base_price&.to_f }
          end

        tenant_categories = Category
          .joins(products: :product_tenant_settings)
          .where(product_tenant_settings: { tenant_id: tenant.id })
          .distinct
          .select(:id, :name, :slug, :is_active)
          .map { |c| { id: c.id, name: c.name, slug: c.slug, is_active: c.is_active } }

        pts_data = ProductTenantSetting.where(tenant_id: tenant.id).map do |pts|
          { product_id: pts.product_id, price: pts.price&.to_f,
            is_enabled: pts.is_enabled, is_sold_out: pts.is_sold_out }
        end

        render json: {
          resolved_tenant: { id: tenant.id, slug: tenant.slug, name: tenant.name },
          products_for_tenant: tenant_products,
          categories_for_tenant: tenant_categories,
          product_tenant_settings: pts_data
        }
      end
    end
  end
end
