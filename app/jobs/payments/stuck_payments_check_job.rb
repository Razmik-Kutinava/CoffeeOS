# frozen_string_literal: true

module Payments
  # Проверяет платежи которые завязли в pending/processing дольше 30 минут.
  # Шлёт алерт в Telegram. Запускать периодически (например каждые 15 минут).
  class StuckPaymentsCheckJob < ApplicationJob
    queue_as :default

    STUCK_THRESHOLD = 30.minutes

    def perform
      stuck = Payment
        .pending_or_processing
        .where("payments.created_at < ?", STUCK_THRESHOLD.ago)
        .where(provider: "tbank")
        .includes(:order)
        .limit(50)

      return if stuck.none?

      stuck.each do |payment|
        TelegramAlertJob.perform_later(
          "⏳ Зависший платёж Т-Банк ##{payment.id}\n" \
          "Заказ ##{payment.order_id}, сумма #{payment.amount}₽, статус #{payment.status}",
          {
            payment_id:         payment.id,
            order_id:           payment.order_id,
            amount:             payment.amount,
            status:             payment.status,
            provider_payment_id: payment.provider_payment_id,
            created_at:         payment.created_at&.strftime("%d.%m %H:%M")
          }
        )
      end

      Rails.logger.warn("[StuckPaymentsCheckJob] #{stuck.size} stuck payment(s) found, alerts sent")
    end
  end
end
