# frozen_string_literal: true

module Shop
  module Api
    class FavoritesController < Shop::Api::BaseController
      before_action :load_favorites

      def index
        ids = @favorites
        return render json: [] if ids.empty?

        tenant_id = @shop_tenant.id
        scope = Shop::Catalog.products_scope(tenant_id).where(id: ids)
        render json: scope.map { |p|
          setting = ProductTenantSetting.find_by!(product_id: p.id, tenant_id: tenant_id)
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
        @favorites |= [ product.id.to_s ]
        session[:shop_favorites] = @favorites
        render json: { favorited: true }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Product not found" }, status: :not_found
      end

      def destroy
        pid = params[:product_id].to_s
        @favorites.reject! { |x| x == pid }
        session[:shop_favorites] = @favorites
        render json: { favorited: false }
      end

      private

      def load_favorites
        session[:shop_favorites] ||= []
        @favorites = session[:shop_favorites].map(&:to_s)
      end
    end
  end
end
