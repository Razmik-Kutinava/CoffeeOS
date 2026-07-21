# frozen_string_literal: true

module Shop
  module Api
    # Quick Repeat Bottom Sheet: частые товары клиента (секция «повторить»)
    # + каталог по категориям для expanded-режима шторки.
    class FrequentProductsController < Shop::Api::BaseController
      def index
        customer_id = Shop::CustomerSession.customer_id(session, @shop_tenant.id)

        frequent_items =
          if customer_id.present?
            Shop::CustomerFrequentProductsService.cached_call(
              customer_id: customer_id,
              tenant_id: @shop_tenant.id
            )
          else
            # Витрина гостевая: без customer в сессии секция «повторить» пуста (не 401)
            []
          end

        render json: { frequent_items: frequent_items, categories: categories_by_name }
      end

      private

      # { "Имя категории" => [карточки] } — те же 3 плоских запроса, что в categories#index
      def categories_by_name
        products = Shop::Catalog.products_scope(@shop_tenant.id).order(:sort_order).to_a
        settings = ProductTenantSetting
          .where(product_id: products.map(&:id), tenant_id: @shop_tenant.id)
          .index_by(&:product_id)
        by_category = products.group_by(&:category_id)
        categories = Category.active.where(id: by_category.keys.compact).order(:sort_order)

        categories.to_h do |category|
          cards = (by_category[category.id] || []).map do |product|
            {
              id: product.id,
              name: product.name,
              price: settings[product.id]&.price&.to_f,
              image_url: product.image_url,
              category: category.name
            }
          end
          [ category.name, cards ]
        end
      end
    end
  end
end
