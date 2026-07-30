# frozen_string_literal: true

module Shop
  # POST widget_init: Init(+Charge по RebillId) с connection_type Widget, сумма из БД.
  # RebillId: явный → primary card order.customer → extra customer_ids (session).
  class WidgetPaymentInitiator
    class Error < StandardError; end

    def self.call(order:, return_base_url:, notification_url:, rebill_id: nil, extra_customer_ids: [])
      new(
        order: order,
        return_base_url: return_base_url,
        notification_url: notification_url,
        rebill_id: rebill_id,
        extra_customer_ids: extra_customer_ids
      ).call
    end

    def initialize(order:, return_base_url:, notification_url:, rebill_id: nil, extra_customer_ids: [])
      @order = order
      @return_base_url = return_base_url
      @notification_url = notification_url
      @rebill_id = rebill_id.to_s.presence
      @extra_customer_ids = Array(extra_customer_ids).compact
    end

    def call
      payment = @order.payments.order(created_at: :desc).first
      raise Error, "Payment missing" unless payment

      rebill_id = @rebill_id || resolve_rebill_id

      if payment.provider_payment_id.present?
        return charge_existing!(payment, rebill_id) if payment.pending? && rebill_id.present?

        return { provider_payment_id: payment.provider_payment_id.to_s }
      end

      result = Payments::TbankInlineInit.call(
        order: @order,
        return_base_url: @return_base_url,
        notification_url: @notification_url,
        rebill_id: rebill_id,
        customer_key: @order.customer_id&.to_s,
        connection_type: "Widget"
      )

      payment.update_columns(
        provider: "tbank",
        provider_payment_id: result[:provider_payment_id]
      )

      Payments::TbankPaymentSync.sync_order!(order: @order) if rebill_id.present?
      result
    end

    private

    def resolve_rebill_id
      customer_ids = [ @order.customer_id, *@extra_customer_ids ].compact.uniq
      customer_ids.each do |cid|
        token = MobilePaymentMethod.primary_for(cid)&.rebill_id
        return token if token.present?
      end
      nil
    end

    # Init уже был (без Charge) — дожимаем Charge по RebillId.
    def charge_existing!(payment, rebill_id)
      adapter = Payments::TbankAdapter.new
      charge_response = adapter.charge(
        payment_id: payment.provider_payment_id,
        rebill_id: rebill_id
      )
      pid = charge_response["PaymentId"].to_s.presence || payment.provider_payment_id.to_s
      payment.update_columns(provider: "tbank", provider_payment_id: pid)
      Payments::TbankPaymentSync.sync_order!(order: @order)
      { provider_payment_id: pid }
    end
  end
end
