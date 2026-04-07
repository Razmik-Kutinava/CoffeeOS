# frozen_string_literal: true

module Shop
  module Api
    class ProductsController < Shop::Api::BaseController
      def index
        tenant_id = @shop_tenant.id
        scope = Shop::Catalog.products_scope(tenant_id)
        rel = scope.includes(:category)
        rel = rel.where(category_id: params[:category_id]) if params[:category_id].present?
        if ActiveModel::Type::Boolean.new.cast(params[:in_stock])
          rel = rel.joins(:product_tenant_settings).where(
            "product_tenant_settings.stock_qty IS NULL OR product_tenant_settings.stock_qty > 0"
          ).distinct
        end

        products = rel.to_a
        settings = ProductTenantSetting
          .where(product_id: products.map(&:id), tenant_id: tenant_id)
          .index_by(&:product_id)

        render json: products.map { |p| product_list_json(p, setting: settings[p.id]) }
      end

      def show
        tenant_id = @shop_tenant.id
        product = Shop::Catalog.products_scope(tenant_id)
          .includes(product_modifier_groups: :product_modifier_options)
          .find(params[:id])
        render json: product_detail_json(product, tenant_id: tenant_id)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Product not found", status: 404 }, status: :not_found
      end

      private

      def product_list_json(product, setting:)
        raise ActiveRecord::RecordNotFound, "Setting not found for product #{product.id}" unless setting
        {
          id: product.id,
          name: product.name,
          description: product.description,
          price: setting.price.to_f,
          stock: Shop::Catalog.stock_for_display(setting),
          category: { id: product.category_id, name: product.category.name }
        }
      end

      def product_detail_json(product, tenant_id:)
        setting = ProductTenantSetting.find_by!(product_id: product.id, tenant_id: tenant_id)
        {
          id: product.id,
          name: product.name,
          description: product.description,
          price: setting.price.to_f,
          stock: Shop::Catalog.stock_for_display(setting),
          image_url: product.image_url,
          volume_ml: nil,
          allergens: nil,
          ingredients: nil,
          nutrition_info: {},
          modifier_groups: product.product_modifier_groups.ordered.map { |g| modifier_group_json(g) }
        }
      end

      def modifier_group_json(group)
        {
          id: group.id,
          name: group.name,
          modifier_type: group.is_required ? "required" : "optional",
          modifiers: group.product_modifier_options.active.ordered.map do |m|
            { id: m.id, name: m.name, price_change: m.price_delta.to_f }
          end
        }
      end
    end
  end
end
