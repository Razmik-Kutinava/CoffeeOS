# frozen_string_literal: true

module Shop
  module Api
    class PaymentsController < Shop::Api::BaseController
      include Shop::Api::OperatingHoursGuard

      before_action :reject_orders_when_closed!, only: %i[new_card one_click sbp_init]

      # GET /shop/api/payments/card_config — RSA public key для CardData.
      def card_config
        render json: Shop::PaymentCryptoConfig.as_api_json
      end

      # POST /shop/api/payments/new_card — Init + FinishAuthorize + save_card.
      def new_card
        result = Shop::NewCardPaymentService.new(session, tenant: @shop_tenant, request: request)
          .call!(payment_params.to_h.symbolize_keys)
        render json: result
      rescue Shop::TbankPaymentError => e
        render_payment_error(e)
      rescue Shop::OrderCreator::Error => e
        render json: { error: e.message, status: 422 }, status: :unprocessable_entity
      end

      # POST /shop/api/payments/one_click — Init → Charge по card_id / RebillId.
      def one_click
        result = Shop::OneClickPaymentService.new(session, tenant: @shop_tenant, request: request)
          .call!(payment_params.to_h.symbolize_keys)
        render json: result
      rescue Shop::TbankPaymentError => e
        render_payment_error(e)
      rescue Shop::OrderCreator::Error => e
        render json: { error: e.message, status: 422 }, status: :unprocessable_entity
      end

      # POST /shop/api/payments/sbp/init — Init+Receipt → GetQr → { payment_url }.
      def sbp_init
        result = Shop::SbpPaymentInitiator.new(tenant: @shop_tenant, request: request)
          .call!(order_id: params.require(:order_id))
        render json: {
          payment_url: result[:payment_url],
          order_id: result[:order_id],
          provider_payment_id: result[:provider_payment_id]
        }
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :bad_request
      rescue Shop::SbpPaymentInitiator::Error => e
        render json: { error: e.message }, status: e.http_status
      end

      private

      def payment_params
        params.permit(
          :name, :email, :phone, :comment, :payment_method, :pickup_time,
          :client_order_uuid, :card_data, :CardData, :save_card, :amount,
          :card_id, :saved_card_id, :order_id
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
