# frozen_string_literal: true

module Shop
  module Api
    class BaseController < Shop::BaseController
      include ErrorHandler
      include Auth

      protect_from_forgery with: :null_session

      around_action :with_shop_tenant!

      private

      def with_shop_tenant!
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
        previous_tenant_id = Current.tenant_id
        Current.tenant_id = tenant.id

        ActiveRecord::Base.transaction do
          conn = ActiveRecord::Base.connection
          conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant.id.to_s)}")
          yield
        end
      ensure
        Current.tenant_id = previous_tenant_id
      end
    end
  end
end
