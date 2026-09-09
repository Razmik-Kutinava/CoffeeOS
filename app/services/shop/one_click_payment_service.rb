# frozen_string_literal: true

module Shop
  # Шаг 4: оплата в 1 клик по card_id → RebillId → Init → Charge.
  class OneClickPaymentService
    def initialize(session, tenant:, request: nil)
      @session = session
      @tenant = tenant
      @request = request
    end

    def call!(params)
      cid = CustomerSession.customer_id(@session, @tenant.id)
      customer = cid.present? ? MobileCustomer.find_by(id: cid) : nil
      if Payments::BindingStepUp.requires_step_up?(customer, session: @session, tenant_id: @tenant.id)
        raise OrderCreator::Error.new(
          "Требуется подтверждение телефона (step-up) перед списанием с сохранённой карты",
          step_up_required: true
        )
      end

      normalized = params.to_h.symbolize_keys
      normalized[:saved_card_id] ||= normalized[:card_id]

      creator = RecurrentOrderCreator.new(@session, tenant: @tenant, request: @request)
      order = creator.call!(normalized)
      card = MobilePaymentMethod.find_by(id: normalized[:saved_card_id])
      result = creator.charge_result

      payload = {
        order_id: order.id,
        status: order.status,
        recurrent_charge: true,
        provider_payment_id: creator.provider_payment_id,
        payment_iframe: false,
        reconnect_token: GuestOrderReconnect.token_for(order),
        saved_card: SavedCardJson.serialize(card || MobilePaymentMethod.primary_for(order.customer_id))
      }

      if result
        payload.merge!(result.as_api_json)
      else
        payload[:tbank_status] = order.accepted? ? "CONFIRMED" : nil
        payload[:error_code] = "0" if order.accepted?
      end

      payload.compact
    rescue RecurrentOrderCreator::Error => e
      raise OrderCreator::Error, e.message
    end
  end
end
