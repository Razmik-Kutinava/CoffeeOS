# frozen_string_literal: true

module Shop
  module Api
    class CategoriesController < Shop::Api::BaseController
      def index
        tenant_id = @shop_tenant.id
        scope = Shop::Catalog.products_scope(tenant_id)
        categories = Category.active.ordered

        data = categories.map { |c| category_json(c, scope) }
        render json: data
      end

      private

      def category_json(category, scope)
        prods = scope.where(category_id: category.id).order(:sort_order)
        {
          id: category.id,
          name: category.name,
          position: category.sort_order,
          products: prods.map { |p| product_summary_json(p, tenant_id: @shop_tenant.id) }
        }
      end

      def product_summary_json(product, tenant_id:)
        setting = ProductTenantSetting.find_by(product_id: product.id, tenant_id: tenant_id)
        {
          id: product.id,
          name: product.name,
          price: setting&.price&.to_f,
          image_url: product.image_url,
          stock: setting ? Shop::Catalog.stock_for_display(setting) : 0
        }
      end
    end
  end
end
