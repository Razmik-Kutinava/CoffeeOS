# frozen_string_literal: true

module Shop
  module Api
    class ConfigController < Shop::Api::BaseController
      def show
        render json: Shop::PaymentConfig.client_json
      end
    end
  end
end
