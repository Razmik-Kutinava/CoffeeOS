# frozen_string_literal: true

module Payments
  # Проверяет платежи которые завязли в pending/processing дольше 30 минут.
  # Сначала GetState/TbankPaymentSync; алерт только если всё ещё stuck / нет pid / ошибка sync.
  class StuckPaymentsCheckJob < ApplicationJob
    queue_as :default

    STUCK_THRESHOLD = 30.minutes

    # Test hook: inject adapter into TbankPaymentSync (nil = real adapter).
    class << self
      attr_accessor :sync_adapter
    end

    def perform
      stuck = Payment
        .pending_or_processing
        .where("payments.created_at < ?", STUCK_THRESHOLD.ago)
        .where(provider: "tbank")
        .includes(:order)
        .limit(50)

      return if stuck.none?

      stuck.each { |payment| process_stuck!(payment) }

      Rails.logger.warn("[StuckPaymentsCheckJob] #{stuck.size} stuck payment(s) processed")
    end

    private

    def process_stuck!(payment)
      if payment.provider_payment_id.blank?
        alert_stuck!(payment)
        return
      end

      begin
        Payments::TbankPaymentSync.new(
          payment: payment,
          adapter: self.class.sync_adapter
        ).sync!
      rescue StandardError => e
        Rails.logger.error(
          "[StuckPaymentsCheckJob] sync failed payment=#{payment.id}: #{e.class}: #{e.message}"
        )
        alert_stuck!(payment)
        return
      end

      payment.reload
      alert_stuck!(payment) if payment.pending? || payment.processing?
    end

    def alert_stuck!(payment)
      TelegramAlertJob.perform_later(
        "⏳ Зависший платёж Т-Банк ##{payment.id}\n" \
        "Заказ ##{payment.order_id}, сумма #{payment.amount}₽, статус #{payment.status}",
        {
          payment_id: payment.id,
          order_id: payment.order_id,
          amount: payment.amount,
          status: payment.status,
          provider_payment_id: payment.provider_payment_id,
          created_at: payment.created_at&.strftime("%d.%m %H:%M")
        }
      )
    end
  end
end
