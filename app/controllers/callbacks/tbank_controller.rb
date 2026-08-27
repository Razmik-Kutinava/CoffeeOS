# frozen_string_literal: true

module Callbacks
  # Webhook от Т-Банка: только проверяет подпись + idempotency + enqueue.
  # Реальная обработка — в Payments::TbankCallbackJob (retry x5).
  class TbankController < ApplicationController
    skip_forgery_protection

    IDEMPOTENCY_TTL = 24.hours
    MAX_BODY_BYTES = 256_000

    def notify
      idem_key = nil
      claimed = false
      done = false
      return render_too_large if body_too_large?

      payload = parse_payload
      return render_bad_request("missing payload") unless payload

      unless Payments::TbankAdapter.verify_notification(payload)
        Rails.logger.warn("[Tbank::Callback] Invalid token, OrderId=#{payload['OrderId']}")
        return render json: { error: "invalid token" }, status: :unauthorized
      end

      # Idempotency: shared Rails.cache (Solid Cache на Fly) — переживает multi-web.
      # Claim до обработки; release только если мы владельцы claim и работа не завершена.
      idem_key = idempotency_key(payload)
      if idem_key
        unless claim_idempotency(idem_key)
          Rails.logger.info("[Tbank::Callback] Duplicate webhook ignored, key=#{idem_key}")
          if fiscal_notification?(payload)
            return render plain: "OK", status: :ok
          end
          return render json: { ok: true, duplicate: true }
        end
        claimed = true
      end

      tbank_status = payload["Status"].to_s

      # #73 NotificationFiscalization: Status=RECEIPT (офиц. дока Т-Банк)
      if fiscal_notification?(payload)
        Payments::TbankFiscalNotificationHandler.new(payload: payload.to_h).call!
        done = true
        Rails.logger.info("[Tbank::Callback] Fiscal RECEIPT OrderId=#{payload['OrderId']} PaymentId=#{payload['PaymentId']}")
        return render plain: "OK", status: :ok
      end

      our_status = Payments::TbankAdapter.map_status(tbank_status)

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

      done = true
      Rails.logger.info("[Tbank::Callback] Enqueued OrderId=#{payload['OrderId']}, status=#{tbank_status}")
      render json: { ok: true }
    rescue StandardError => e
      release_idempotency_claim(idem_key) if claimed && !done
      Rails.logger.error("[Tbank::Callback] Error: #{e.class} #{e.message}")
      render json: { error: "internal error" }, status: :internal_server_error
    end

    private

    def body_too_large?
      return true if request.content_length.to_i > MAX_BODY_BYTES

      body = request.raw_post
      body.present? && body.bytesize > MAX_BODY_BYTES
    end

    def parse_payload
      body = request.raw_post
      return nil if body.blank?

      JSON.parse(body)
    rescue JSON::ParserError
      nil
    end

    def fiscal_notification?(payload)
      status = payload["Status"].to_s.upcase
      return true if status == "RECEIPT"

      payload["NotificationType"].to_s == "NotificationFiscalization"
    end

    def idempotency_key(payload)
      payment_id = payload["PaymentId"].to_s
      status     = payload["Status"].to_s
      return nil if payment_id.blank? || status.blank?

      if status.upcase == "RECEIPT" || payload["NotificationType"].to_s == "NotificationFiscalization"
        fn = payload["FnNumber"].to_s
        fd = payload["FiscalDocumentNumber"].to_s
        fp = payload["FiscalDocumentAttribute"].to_s
        return "tbank:callback:#{payment_id}:RECEIPT:#{fn}:#{fd}:#{fp}"
      end

      "tbank:callback:#{payment_id}:#{status}"
    end

    # Atomic when store supports unless_exist (MemoryStore / Solid Cache / Redis).
    def claim_idempotency(key)
      Rails.cache.write(key, 1, expires_in: IDEMPOTENCY_TTL, unless_exist: true)
    end

    def release_idempotency_claim(key)
      return if key.blank?

      Rails.cache.delete(key)
      Rails.logger.info("[Tbank::Callback] Released idempotency claim key=#{key}")
    end

    def render_too_large
      render json: { error: "too large" }, status: :content_too_large
    end

    def render_bad_request(msg)
      render json: { error: msg }, status: :bad_request
    end
  end
end
