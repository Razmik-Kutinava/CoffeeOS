# frozen_string_literal: true

module Shop
  module Api
    class CategoriesController < Shop::Api::BaseController
      skip_before_action :authenticate_shop_api!, only: [:index]

      def index
        tenant_id = @shop_tenant.id
        scope = Shop::Catalog.products_scope(tenant_id)

        # Кэширование с ключом по tenant_id и пагинации
        cache_key = "shop/categories/#{tenant_id}/#{params[:page]}/#{params[:per_page]}"
        cached_data = safe_cache_read(cache_key)
        return render json: cached_data if cached_data

        # 1 запрос: все товары
        all_products = scope.order(:sort_order).to_a

        # 1 запрос: все настройки, хэш product_id => setting
        settings = ProductTenantSetting
          .where(product_id: all_products.map(&:id), tenant_id: tenant_id)
          .index_by(&:product_id)

        products_by_category = all_products.group_by(&:category_id)

        # 1 запрос: категории
        categories = Category.where(id: products_by_category.keys.compact).order(:sort_order)

        # Пагинация по категориям (витрина без per_page — отдаём все категории, до 50)
        page = [params[:page].to_i, 1].max
        default_per_page = 50
        per_page = if params[:per_page].present?
          [[params[:per_page].to_i, 1].max, default_per_page].min
        else
          default_per_page
        end
        categories = categories.limit(per_page).offset((page - 1) * per_page)

        data = categories.map do |cat|
          prods = products_by_category[cat.id] || []
          {
            id: cat.id,
            name: cat.name,
            position: cat.sort_order,
            products: prods.map { |p| product_summary_json(p, setting: settings[p.id]) }
          }
        end
        response_data = {
          data: data,
          meta: { page: page, per_page: per_page }
        }
        safe_cache_write(cache_key, response_data)
        render json: response_data
      end

      private

      def safe_cache_read(key)
        Rails.cache.read(key)
      rescue StandardError => e
        Rails.logger.warn("[Shop::API][categories] cache read skipped: #{e.class}: #{e.message}")
        nil
      end

      def safe_cache_write(key, payload)
        Rails.cache.write(key, payload, expires_in: 5.minutes)
      rescue StandardError => e
        Rails.logger.warn("[Shop::API][categories] cache write skipped: #{e.class}: #{e.message}")
      end

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
