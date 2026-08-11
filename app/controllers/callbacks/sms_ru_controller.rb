# frozen_string_literal: true

module Callbacks
  # Webhook SMS.ru (sms_status / callcheck_status).
  # Канон ответа провайдера: тело "100" (иначе SMS.ru ретраит до 5 суток).
  class SmsRuController < ApplicationController
    skip_forgery_protection

    MAX_BODY_BYTES = 256_000

    def notify
      if request.content_length.to_i > MAX_BODY_BYTES
        return render plain: "too large", status: :payload_too_large, content_type: "text/plain"
      end

      entries = normalize_entries(params[:data])
      hash = params[:hash].to_s

      Callbacks::SmsRuWebhook.call!(entries: entries, hash: hash)
      render plain: "100", content_type: "text/plain"
    rescue Callbacks::SmsRuWebhook::PayloadTooLargeError => e
      Rails.logger.warn("[SmsRu::Callback] #{e.message}")
      render plain: "too large", status: :payload_too_large, content_type: "text/plain"
    rescue Callbacks::SmsRuWebhook::InvalidHashError => e
      Rails.logger.warn("[SmsRu::Callback] #{e.message}")
      render plain: "invalid hash", status: :unauthorized, content_type: "text/plain"
    rescue StandardError => e
      Rails.logger.error("[SmsRu::Callback] #{e.class}: #{e.message}")
      # Не "100" — SMS.ru повторит; иначе тихо теряем событие.
      render plain: "error", status: :internal_server_error, content_type: "text/plain"
    end

    private

    # SMS.ru шлёт data[1], data[2]… → Hash {"1"=>…} или Array.
    def normalize_entries(raw)
      case raw
      when Hash, ActionController::Parameters
        raw.to_unsafe_h.sort_by { |k, _| k.to_i }.map { |_, v| v }
      when Array
        raw
      else
        []
      end
    end
  end
end
