# frozen_string_literal: true

module Shop
  module Api
    class TenantsController < Shop::Api::BaseController
      def index
        render json: Shop::CustomerTenantHistory.call(session: session, current_tenant: @shop_tenant)
      end
    end
  end
end
