# frozen_string_literal: true

module Shop
  module Api
    class FavoritesController < Shop::Api::BaseController
      def index
        ids = favorites_store.product_ids
        return render json: [] if ids.empty?

        tenant_id = @shop_tenant.id
        products = Shop::Catalog.products_scope(tenant_id).where(id: ids).to_a
        settings = ProductTenantSetting
          .where(product_id: products.map(&:id), tenant_id: tenant_id)
          .index_by(&:product_id)

        render json: products.filter_map { |p|
          setting = settings[p.id]
          next unless setting

          {
            id: p.id,
            name: p.name,
            price: setting.price.to_f,
            image_url: p.image_url,
            description: p.description,
            category_id: p.category_id
          }
        }
      end

      def create
        product = Shop::Catalog.products_scope(@shop_tenant.id).find(params[:product_id])
        favorites_store.add!(product.id)
        render json: { favorited: true }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Product not found" }, status: :not_found
      end

      def destroy
        favorites_store.remove!(params[:product_id])
        render json: { favorited: false }
      end

      private

      def favorites_store
        @favorites_store ||= Shop::FavoritesStore.new(
          session: session,
          tenant: @shop_tenant,
          customer_id: Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        )
      end
    end
  end
end
