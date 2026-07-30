# frozen_string_literal: true

module Shop
  # POST widget_init: Init(+Charge по RebillId) с connection_type Widget, сумма из БД.
  # Если у заказа уже есть provider_payment_id — не дублируем Init (OrderId в Т-Банке уникален).
  class WidgetPaymentInitiator
    class Error < StandardError; end

    def self.call(order:, return_base_url:, notification_url:)
      new(order: order, return_base_url: return_base_url, notification_url: notification_url).call
    end

    def initialize(order:, return_base_url:, notification_url:)
      @order = order
      @return_base_url = return_base_url
      @notification_url = notification_url
    end

    def call
      payment = @order.payments.order(created_at: :desc).first
      raise Error, "Payment missing" unless payment

      if payment.provider_payment_id.present?
        return { provider_payment_id: payment.provider_payment_id.to_s }
      end

      rebill_id = MobilePaymentMethod.primary_for(@order.customer_id)&.rebill_id
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

      # После Charge статус может уже быть AUTHORIZED/CONFIRMED — подтянем GetState.
      Payments::TbankPaymentSync.sync_order!(order: @order) if rebill_id.present?

      result
    end
  end
end
