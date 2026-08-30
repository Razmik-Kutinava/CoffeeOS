# frozen_string_literal: true

module Shop
  module Api
    class PaymentsController < Shop::Api::BaseController
      include Shop::Api::OperatingHoursGuard
      include Shop::Api::OrderOwnership

      before_action :reject_orders_when_closed!, only: %i[new_card one_click sbp_init sbp_charge widget_init]

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
        order = find_visible_order!(params.require(:order_id))
        result = Shop::SbpPaymentInitiator.new(tenant: @shop_tenant, request: request)
          .call!(
            order_id: order.id,
            save_sbp_account: params[:save_sbp_account]
          )
        render json: {
          payment_url: result[:payment_url],
          order_id: result[:order_id],
          provider_payment_id: result[:provider_payment_id]
        }
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :bad_request
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Order not found" }, status: :not_found
      rescue Shop::SbpPaymentInitiator::Error => e
        render json: {
          error: e.message,
          error_code: e.error_code
        }, status: e.http_status
      end

      # POST /shop/api/payments/sbp/charge — Zero-Click ChargeQr по AccountToken.
      def sbp_charge
        session_cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        find_visible_order!(params.require(:order_id))
        result = Shop::SbpAutopayChargeService.new(tenant: @shop_tenant, request: request)
          .call!(order_id: params.require(:order_id), customer_id: session_cid)
        render json: {
          order_id: result[:order_id],
          status: result[:status],
          amount: result[:amount],
          provider_payment_id: result[:provider_payment_id]
        }.compact
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :bad_request
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Order not found" }, status: :not_found
      rescue Shop::SbpAutopayChargeService::Error => e
        render json: {
          error: e.message,
          error_code: e.error_code,
          fatal: e.fatal?
        }.compact, status: e.http_status
      end

      # POST /shop/api/payments/widget_init — Widget SDK: сумма из БД, connection_type: Widget.
      def widget_init
        order = find_visible_order!(params[:order_id])

        session_cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        email_cid = Shop::GuestCustomerResolver.call(
          session: session,
          tenant_id: @shop_tenant.id,
          email: params[:email]
        )
        rebill_id = rebill_id_from_card_param(order)

        result = Shop::WidgetPaymentInitiator.call(
          order: order,
          return_base_url: ENV.fetch("TBANK_RETURN_URL", request.base_url),
          notification_url: "#{request.base_url}/callbacks/tbank",
          rebill_id: rebill_id,
          extra_customer_ids: [ session_cid, email_cid ]
        )

        render json: { paymentUrl: adapter_payment_url(result), order_id: order.id.to_s }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Order not found" }, status: :not_found
      rescue Shop::WidgetPaymentInitiator::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue Payments::TbankAdapter::ApiError => e
        Rails.logger.warn("[Shop::Payments#widget_init] ApiError order=#{params[:order_id]} code=#{e.error_code} msg=#{e.message}")
        render json: { error: "Payment provider error", error_code: e.error_code }, status: :unprocessable_entity
      rescue Payments::TbankAdapter::Error
        render json: { error: "Payment provider unavailable" }, status: :service_unavailable
      end

      # GET /shop/api/payments/status/:order_id — PENDING|CONFIRMED|REJECTED|CANCELED.
      def status
        order = find_visible_order!(params[:order_id])
        order = Order.includes(:payments).find(order.id)

      # Шаг 2 ТЗ: sync статуса через GetState; при AUTHORIZED инициируем Confirm.
      Payments::TbankPaymentSync.sync_order!(order: order)

      # sync_order! обновляет Payment в БД, а payments может быть заранее загружен через includes.
      # Чтобы presenter вернул актуальный статус — перезагружаем association.
      order.payments.reload

        render json: Shop::PaymentStatusPresenter.call(order)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Order not found" }, status: :not_found
      end

      private

      def payment_params
        params.permit(
          :name, :email, :phone, :comment, :payment_method, :pickup_time,
          :client_order_uuid, :card_data, :CardData, :save_card, :amount,
          :card_id, :saved_card_id, :order_id
        )
      end

      def adapter_payment_url(result)
        pid = result[:provider_payment_id]
        "https://securepayments.tinkoff.ru/#{pid}"
      end

      # card_id / saved_card_id → RebillId; карта должна принадлежать клиенту заказа / сессии / email.
      def rebill_id_from_card_param(order)
        card_id = params[:card_id].presence || params[:saved_card_id].presence
        return nil if card_id.blank?

        card = MobilePaymentMethod.find_by(id: card_id, is_active: true)
        return nil unless card

        session_cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        email_cid = Shop::GuestCustomerResolver.call(
          session: session,
          tenant_id: @shop_tenant.id,
          email: params[:email]
        )
        allowed = [ order.customer_id.to_s, session_cid.to_s, email_cid.to_s ].compact_blank
        return nil unless allowed.include?(card.customer_id.to_s)

        card.rebill_id
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
