# frozen_string_literal: true

module Shop
  # #39 v2 — платный fallback каскада: только SMS.ru (+ order_notification_logs).
  # Telegram убран из каскада (см. ТЗ v2).
  class OrderReadyPaidNotifier
    SMS_TEMPLATE = "CODE:BLACK. Заказ готов! #%s"

    def self.call(order:)
      new(order).call
    end

    def initialize(order)
      @order = order
    end

    def call
      customer = MobileCustomer.find_by(id: @order.customer_id)
      return if customer.blank?

      deliver_sms!(customer)
    end

    private

    def deliver_sms!(customer)
      phone = customer.phone
      if phone.blank?
        Rails.logger.warn("[Cascade][Order ##{@order.id}] SMS skipped: no phone")
        return
      end

      msg = format(SMS_TEMPLATE, @order.order_number)
      Shop::SmsRuClient.send_message!(phone: phone, msg: msg)
      write_log!(channel: "sms", status: "sent", payload: { msg: msg, to: phone })
      Rails.logger.info("[Cascade][Order ##{@order.id}] SMS delivered.")
    rescue Shop::SmsRuClient::ValidationError => e
      write_log!(channel: "sms", status: "failed", error: e.message, payload: { msg: msg })
      raise
    rescue Shop::SmsRuClient::Error => e
      write_log!(channel: "sms", status: "failed", error: e.message, payload: { msg: msg })
      Rails.logger.warn(
        "[Cascade][Order ##{@order.id}] SMS.ru delivery failed: #{e.message}"
      )
    end

    def write_log!(channel:, status:, error: nil, payload: {})
      OrderNotificationLog.create!(
        order_id: @order.id,
        tenant_id: @order.tenant_id,
        channel: channel,
        status: status,
        error_message: error,
        payload: payload
      )
    end
  end
end
