# frozen_string_literal: true

module Callbacks
  # Webhook от Т-Банка: только проверяет подпись + idempotency + enqueue.
  # Реальная обработка — в Payments::TbankCallbackJob (retry x5).
  class TbankController < ApplicationController
    skip_forgery_protection

    IDEMPOTENCY_TTL = 24.hours

    def notify
      idem_key = nil
      payload = parse_payload
      return render_bad_request("missing payload") unless payload

      unless Payments::TbankAdapter.verify_notification(payload)
        Rails.logger.warn("[Tbank::Callback] Invalid token, OrderId=#{payload['OrderId']}")
        return render json: { error: "invalid token" }, status: :unauthorized
      end

      # Idempotency: Т-Банк повторяет webhook при таймауте.
      # Ключ по PaymentId + Status — защищаем от дублирования.
      # Claim до обработки; при полном фейле (500) — release, иначе retry банка залипнет.
      idem_key = idempotency_key(payload)
      if idem_key && !Payments::CacheCounter.claim(idem_key, expires_in: IDEMPOTENCY_TTL)
        Rails.logger.info("[Tbank::Callback] Duplicate webhook ignored, key=#{idem_key}")
        return render json: { ok: true, duplicate: true }
      end

      tbank_status = payload["Status"].to_s
      our_status   = Payments::TbankAdapter.map_status(tbank_status)

      unless our_status
        Rails.logger.info("[Tbank::Callback] Ignored status=#{tbank_status} for OrderId=#{payload['OrderId']}")
        return render json: { ok: true }
      end

      # Обработка на web-процессе: worker на Fly часто stopped → perform_later не бежит,
      # RebillId из webhook теряется (finalize/GetState без RebillId). Retry через очередь — fallback.
      begin
        Payments::TbankCallbackJob.perform_now(payload.to_h)
      rescue StandardError => e
        Rails.logger.error("[Tbank::Callback] perform_now failed, enqueue: #{e.class} #{e.message}")
        begin
          Payments::TbankCallbackJob.perform_later(payload.to_h)
        rescue SolidQueue::Job::EnqueueError, ActiveRecord::StatementInvalid => enqueue_err
          Rails.logger.warn("[Tbank::Callback] Queue unavailable: #{enqueue_err.class}")
          raise e
        end
      end

      Rails.logger.info("[Tbank::Callback] Enqueued OrderId=#{payload['OrderId']}, status=#{tbank_status}")
      render json: { ok: true }
    rescue StandardError => e
      release_idempotency_claim(idem_key)
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

    def idempotency_key(payload)
      payment_id = payload["PaymentId"].to_s
      status     = payload["Status"].to_s
      return nil if payment_id.blank? || status.blank?

      "tbank:callback:#{payment_id}:#{status}"
    end

    def release_idempotency_claim(key)
      return if key.blank?

      Payments::CacheCounter.delete(key)
      Rails.logger.info("[Tbank::Callback] Released idempotency claim key=#{key}")
    end

    def render_bad_request(msg)
      render json: { error: msg }, status: :bad_request
    end
  end
end
