# frozen_string_literal: true

module Shop
  # #39 — платные каналы каскада: Telegram → SMS.ru (+ order_notification_logs).
  class OrderReadyPaidNotifier
    TG_TEMPLATE = "Ваш заказ в CODE:BLACK готов к выдаче! /shop/#/order/%s"
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

      if customer.telegram_chat_id.present?
        return if deliver_telegram!(customer)
      end

      deliver_sms!(customer)
    end

    private

    def deliver_telegram!(customer)
      text = format(TG_TEMPLATE, @order.id)
      Shop::TelegramBotClient.send_message!(chat_id: customer.telegram_chat_id, text: text)
      write_log!(channel: "telegram", status: "sent", payload: { chat_id: customer.telegram_chat_id })
      Rails.logger.info("[Cascade][Order ##{@order.id}] Telegram message delivered.")
      true
    rescue Shop::TelegramBotClient::BadRequestError => e
      Rails.logger.info(
        "[Cascade][Order ##{@order.id}] Telegram failed (400). Fallback to SMS initiated."
      )
      write_log!(channel: "telegram", status: "failed", error: e.message, payload: { http_status: 400 })
      customer.update!(telegram_chat_id: nil)
      false
    rescue Shop::TelegramBotClient::ForbiddenError => e
      Rails.logger.info(
        "[Cascade][Order ##{@order.id}] Telegram failed (403). Fallback to SMS initiated."
      )
      write_log!(channel: "telegram", status: "failed", error: e.message, payload: { http_status: 403 })
      false
    rescue Shop::TelegramBotClient::Error => e
      status = e.http_status || 500
      Rails.logger.info(
        "[Cascade][Order ##{@order.id}] Telegram failed (#{status}/5xx). Fallback to SMS initiated."
      )
      write_log!(channel: "telegram", status: "failed", error: e.message, payload: { http_status: status })
      false
    end

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
      Rails.logger.warn("[Cascade][Order ##{@order.id}] SMS failed: #{e.message}")
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
