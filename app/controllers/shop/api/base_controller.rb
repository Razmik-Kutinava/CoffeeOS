# frozen_string_literal: true

module Shop
  module Api
    class BaseController < Shop::BaseController
      protect_from_forgery with: :exception

      before_action :require_shop_tenant!

      private

      def require_shop_tenant!
        tid = resolved_shop_tenant_id
        unless tid
          return render json: {
            error: "Не задана точка: параметр tenant_id, заголовок X-Shop-Tenant или SHOP_DEFAULT_TENANT_ID в .env"
          }, status: :unprocessable_entity
        end

        tenant = Tenant.find_by(id: tid)
        unless tenant
          return render json: { error: "Точка не найдена" }, status: :not_found
        end

        @shop_tenant = tenant
        apply_shop_tenant!(tenant)
      end
    end
  end
end
