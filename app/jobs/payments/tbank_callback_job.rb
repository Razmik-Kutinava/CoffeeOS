# frozen_string_literal: true

module Payments
  # Обрабатывает webhook от Т-Банка асинхронно.
  # Контроллер только проверяет подпись + enqueue — быстро возвращает 200 Т-Банку.
  # Этот джоб делает реальную работу с retry.
  class TbankCallbackJob < ApplicationJob
    queue_as :critical

    retry_on StandardError, wait: :polynomially_longer, attempts: 5
    discard_on Callbacks::PaymentStatusUpdater::InvalidStatusError

    def perform(payload)
      tbank_payment_id = payload["PaymentId"].to_s
      tbank_status     = payload["Status"].to_s
      order_id         = payload["OrderId"].to_s

      our_status = Payments::TbankAdapter.map_status(tbank_status)
      return unless our_status

      payment = Payment
        .joins(:order)
        .where(orders: { id: order_id })
        .where(provider_payment_id: tbank_payment_id)
        .first

      payment ||= Payment
        .joins(:order)
        .where(orders: { id: order_id }, provider: "tbank", status: :pending)
        .where(provider_payment_id: [nil, ""])
        .order(created_at: :desc)
        .first

      unless payment
        Rails.logger.warn("[TbankCallbackJob] Payment not found, OrderId=#{order_id}, PaymentId=#{tbank_payment_id}")
        return
      end

      Callbacks::PaymentStatusUpdater.new(
        payment:             payment,
        new_status:          our_status,
        provider_data:       payload.except("Token", "Password"),
        provider_payment_id: tbank_payment_id,
        note:                "Т-Банк: #{tbank_status}"
      ).call!

      # Extreme/Exit#7: webhook upsert UserCards (idempotent по RebillId / pan+exp).
      if tbank_status.to_s.upcase == "CONFIRMED" && payload["RebillId"].to_s.present?
        begin
          Payments::SavedCardStore.persist_from_tbank!(payment: payment.reload, payload: payload)
        rescue StandardError => e
          Rails.logger.error("[TbankCallbackJob] UserCards persist failed: #{e.class}: #{e.message}")
        end
      end

      Rails.logger.info("[TbankCallbackJob] Processed OrderId=#{order_id}, status=#{tbank_status}→#{our_status}")
    end
  end
end
