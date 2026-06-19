# frozen_string_literal: true

module Shop
  module Api
    class ConfigController < Shop::Api::BaseController
      def show
        render json: Shop::PaymentConfig.client_json.merge(
          firebase: Shop::FirebaseConfig.client_json,
          push_configured: Shop::FirebaseConfig.client_configured?,
          operating_hours: Shop::OperatingHours.for(@shop_tenant).client_json
        )
      end
    end
  end
end
