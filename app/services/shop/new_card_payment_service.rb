# frozen_string_literal: true

module Shop
  # Документ 1 / nonPCI: Init → FinishAuthorize + save_card (B1.12-R1 rev2).
  class NewCardPaymentService
    def initialize(session, tenant:, request: nil)
      @session = session
      @tenant = tenant
      @request = request
    end

    def call!(params)
      raise OrderCreator::Error, "Режим имитации оплаты: nonPCI недоступен" if simulate?

      card_data = params[:card_data].to_s.presence
      raise OrderCreator::Error, "Укажите card_data" if card_data.blank?

      save_card = ActiveModel::Type::Boolean.new.cast(params.fetch(:save_card, true))
      order_creator = OrderCreator.new(@session, tenant: @tenant, request: @request)
      order = order_creator.call!(order_params(params), gateway: false)
      payment = order.payments.order(created_at: :desc).first
      raise OrderCreator::Error, "Платёж не создан" unless payment&.pending?

      adapter = Payments::TbankAdapter.new
      urls = gateway_urls

      init = adapter.init_payment(
        order: order,
        return_base_url: urls[:return_base_url],
        notification_url: urls[:notification_url],
        customer_key: order.customer_id.to_s,
        recurrent: save_card
      )
      payment.update_columns(provider: "tbank", provider_payment_id: init[:provider_payment_id])

      raw = adapter.finish_authorize(
        payment_id: init[:provider_payment_id],
        card_data: card_data
      )
      result = Payments::TbankPaymentResult.new(raw)

      unless result.success?
        void_order!(order, payment)
        raise TbankPaymentError.from_api(
          error_code: result.error_code,
          message: result.message.presence || "Ошибка банка",
          tbank_status: result.status
        )
      end

      if result.confirmed?
        settle_confirmed!(order, payment, raw, save_card: save_card)
      elsif result.three_ds?
        Shop::PendingOrderSession.set!(@session, @tenant.id, order.id)
      else
        void_order!(order, payment)
        raise TbankPaymentError.from_api(
          error_code: result.error_code,
          message: result.message.presence || "Платёж отклонён",
          tbank_status: result.status
        )
      end

      build_response(order, result, save_card: save_card)
    rescue Payments::TbankAdapter::ApiError => e
      raise TbankPaymentError.from_api(error_code: e.error_code, message: e.api_message)
    rescue Payments::TbankAdapter::Error => e
      raise OrderCreator::Error, e.message
    end

    private

    def simulate?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("SHOP_SIMULATE_PAYMENT", "1"))
    end

    def order_params(params)
      params.slice(:name, :email, :phone, :comment, :payment_method, :pickup_time, :client_order_uuid)
        .symbolize_keys
        .merge(payment_method: "card")
    end

    def gateway_urls
      base = ENV.fetch("TBANK_RETURN_URL", @request&.base_url.to_s)
      { return_base_url: base, notification_url: "#{base}/callbacks/tbank" }
    end

    def settle_confirmed!(order, payment, raw, save_card:)
      Callbacks::PaymentStatusUpdater.new(
        payment: payment,
        new_status: "succeeded",
        provider_data: raw.except("Token", "Password"),
        provider_payment_id: raw["PaymentId"].to_s.presence || payment.provider_payment_id,
        note: "FinishAuthorize CONFIRMED"
      ).call!
      order.reload
      if save_card && raw["RebillId"].to_s.present?
        Payments::SavedCardStore.persist_from_tbank!(payment: payment.reload, payload: raw)
      end
      Shop::CartService.new(@session, @tenant.id).clear! if order.accepted?
      Shop::PendingOrderSession.clear!(@session, @tenant.id)
    end

    def void_order!(order, payment)
      return unless order.pending_payment?

      order.update!(status: :cancelled)
      payment.update!(status: :failed) if payment.pending?
      Shop::PendingOrderSession.clear!(@session, @tenant.id)
    end

    def build_response(order, result, save_card:)
      card = save_card ? MobilePaymentMethod.primary_for(order.customer_id) : nil
      {
        order_id: order.id,
        status: order.status,
        save_card: save_card,
        reconnect_token: GuestOrderReconnect.token_for(order),
        saved_card: SavedCardJson.serialize(card)
      }.merge(result.as_api_json).compact
    end
  end
end
