# frozen_string_literal: true

module Shop
  module Api
    module OperatingHoursGuard
      extend ActiveSupport::Concern

      private

      def reject_orders_when_closed!
        hours = Shop::OperatingHours.for(@shop_tenant)
        return if hours.open_now?

        payload = hours.client_json
        render json: payload.merge(
          error: payload[:closed_message] || "Точка сейчас закрыта",
          status: 422
        ), status: :unprocessable_entity
      end
    end
  end
end
