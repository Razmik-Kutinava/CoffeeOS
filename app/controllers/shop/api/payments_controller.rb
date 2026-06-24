# frozen_string_literal: true

module Shop
  module Api
    class PaymentsController < Shop::Api::BaseController
      include Shop::Api::OperatingHoursGuard

      before_action :reject_orders_when_closed!, only: %i[new_card one_click]

      # POST /shop/api/payments/new_card — Init + FinishAuthorize (документ 1, эндпоинт 1).
      def new_card
        result = Shop::NewCardPaymentService.new(session, tenant: @shop_tenant, request: request)
          .call!(payment_params.to_h.symbolize_keys)
        render json: result
      rescue Shop::TbankPaymentError => e
        render_payment_error(e)
      rescue Shop::OrderCreator::Error => e
        render json: { error: e.message, status: 422 }, status: :unprocessable_entity
      end

      # POST /shop/api/payments/one_click — Init + Charge по RebillId (документ 1, эндпоинт 2).
      def one_click
        result = Shop::OneClickPaymentService.new(session, tenant: @shop_tenant, request: request)
          .call!(payment_params.to_h.symbolize_keys)
        render json: result
      rescue Shop::TbankPaymentError => e
        render_payment_error(e)
      rescue Shop::OrderCreator::Error => e
        render json: { error: e.message, status: 422 }, status: :unprocessable_entity
      end

      private

      def payment_params
        params.permit(
          :name, :email, :phone, :comment, :payment_method, :pickup_time,
          :client_order_uuid, :card_data, :save_card, :card_id, :saved_card_id
        )
      end

      def render_payment_error(error)
        render json: {
          error: error.message,
          error_code: error.error_code,
          tbank_status: error.tbank_status,
          status: 422
        }, status: :unprocessable_entity
      end
    end
  end
end
