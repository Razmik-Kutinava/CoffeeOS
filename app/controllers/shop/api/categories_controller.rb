# frozen_string_literal: true

module Shop
  module Api
    class CategoriesController < Shop::Api::BaseController
      def index
        tenant_id = @shop_tenant.id
        scope = Shop::Catalog.products_scope(tenant_id)

        # 1 запрос: все товары
        all_products = scope.order(:sort_order).to_a

        # 1 запрос: все настройки, хэш product_id => setting
        settings = ProductTenantSetting
          .where(product_id: all_products.map(&:id), tenant_id: tenant_id)
          .index_by(&:product_id)

        products_by_category = all_products.group_by(&:category_id)

        # 1 запрос: категории
        categories = Category.where(id: products_by_category.keys.compact).order(:sort_order)

        data = categories.map do |cat|
          prods = products_by_category[cat.id] || []
          {
            id: cat.id,
            name: cat.name,
            position: cat.sort_order,
            products: prods.map { |p| product_summary_json(p, setting: settings[p.id]) }
          }
        end
        render json: data
      end

      private

      def product_summary_json(product, setting:)
        {
          id: product.id,
          name: product.name,
          description: product.description,
          price: setting&.price&.to_f,
          image_url: product.image_url,
          stock: setting ? Shop::Catalog.stock_for_display(setting) : 0
        }
      end
    end
  end
end
