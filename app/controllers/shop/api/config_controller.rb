# frozen_string_literal: true

module Shop
  module Api
    class ConfigController < Shop::Api::BaseController
      def show
        history = Shop::CustomerTenantHistory.call(session: session, current_tenant: @shop_tenant)
        render json: Shop::PaymentConfig.client_json.merge(
          firebase: Shop::FirebaseConfig.client_json,
          push_configured: Shop::FirebaseConfig.client_configured?,
          operating_hours: Shop::OperatingHours.for(@shop_tenant).client_json,
          tenant: Shop::TenantAddress.client_json(@shop_tenant),
          last_ordered_tenant_id: history[:last_ordered_tenant_id]
        )
      end
    end
  end
end
