# frozen_string_literal: true

module Callbacks
  # Обработчик webhook-уведомлений от Т-Банка (интернет-эквайринг).
  # Т-Банк шлёт POST с JSON, авторизация — Token (SHA256 отсортированных значений + Password).
  # Docs: https://www.tbank.ru/kassa/dev/payments/#tag/Notifikacii
  class TbankController < ApplicationController
    skip_forgery_protection

    def notify
      payload = parse_payload
      return render_bad_request("missing payload") unless payload

      unless Payments::TbankAdapter.verify_notification(payload)
        Rails.logger.warn("[Tbank::Callback] Invalid token, OrderId=#{payload['OrderId']}")
        return render json: { error: "invalid token" }, status: :unauthorized
      end

      order_id           = payload["OrderId"].to_s
      tbank_payment_id   = payload["PaymentId"].to_s
      tbank_status       = payload["Status"].to_s
      our_status         = Payments::TbankAdapter.map_status(tbank_status)

      unless our_status
        Rails.logger.info("[Tbank::Callback] Ignored status=#{tbank_status} for OrderId=#{order_id}")
        return render json: { ok: true }
      end

      payment = Payment
        .joins(:order)
        .where(orders: { id: order_id })
        .where(provider_payment_id: tbank_payment_id)
        .or(
          Payment.joins(:order).where(orders: { id: order_id }).where(provider: "tbank")
        )
        .order(created_at: :desc)
        .first

      unless payment
        Rails.logger.warn("[Tbank::Callback] Payment not found, OrderId=#{order_id}, PaymentId=#{tbank_payment_id}")
        return render json: { error: "payment not found" }, status: :not_found
      end

      Callbacks::PaymentStatusUpdater.new(
        payment: payment,
        new_status: our_status,
        provider_data: payload.except("Token", "Password"),
        provider_payment_id: tbank_payment_id,
        note: "Т-Банк: #{tbank_status}"
      ).call!

      Rails.logger.info("[Tbank::Callback] Processed OrderId=#{order_id}, status=#{tbank_status}→#{our_status}")

      render json: { ok: true }
    rescue Callbacks::PaymentStatusUpdater::InvalidStatusError => e
      Rails.logger.error("[Tbank::Callback] InvalidStatus: #{e.message}")
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error("[Tbank::Callback] Error: #{e.class} #{e.message}")
      render json: { error: "internal error" }, status: :internal_server_error
    end

    private

    def parse_payload
      body = request.raw_post
      return nil if body.blank?

      JSON.parse(body)
    rescue JSON::ParserError
      nil
    end

    def render_bad_request(msg)
      render json: { error: msg }, status: :bad_request
    end
  end
end
