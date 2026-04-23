module Callbacks
  class EventsController < ApplicationController
    skip_forgery_protection
    before_action :prepare_callback_context
    before_action :authenticate_callback!
    before_action :authenticate_callback_hmac!
    before_action :enforce_anti_replay!
    before_action :enforce_idempotency!

    def payment
      tenant_id = params[:tenant_id]
      payment = find_payment!(tenant_id)
      provider_data = normalize_payload(params[:provider_data])

      new_status = params[:status].to_s
      unless Payment.statuses.key?(new_status)
        return render json: { error: "invalid payment status" }, status: :unprocessable_entity
      end

      old_status = payment.status
      payment.with_lock do
        payment.status = new_status
        payment.provider_data = (payment.provider_data || {}).merge(provider_data)
        payment.provider_payment_id = params[:provider_payment_id] if params[:provider_payment_id].present?
        payment.paid_at = Time.current if new_status == "succeeded" && payment.paid_at.blank?
        payment.save!

        if old_status != new_status
          PaymentStatusLog.create!(
            payment: payment,
            status_from: old_status,
            status_to: new_status,
            source: "callback",
            note: params[:note],
            provider_response: provider_data
          )
        end

        # FIX: Move order update inside payment transaction to prevent race condition
        if payment.status == "succeeded" && payment.order.status == "pending_payment"
          payment.order.update!(status: "accepted")
          OrderStatusLog.create!(
            order: payment.order,
            status_from: "pending_payment",
            status_to: "accepted",
            changed_by_id: nil,
            source: "payment_callback",
            comment: "Оплата подтверждена callback"
          )
        end
      end

      audit_event(
        state: "processed",
        callback_type: "payment",
        tenant_id: tenant_id,
        record_id: payment.id,
        details: { status: payment.status, provider_payment_id: payment.provider_payment_id }
      )

      render json: { ok: true, payment_id: payment.id, status: payment.status }
    rescue ActiveRecord::RecordNotFound
      audit_event(state: "failed", callback_type: "payment", tenant_id: params[:tenant_id], details: { error: "payment not found" })
      render json: { error: "payment not found" }, status: :not_found
    end

    def fiscal_receipt
      tenant_id = params[:tenant_id]
      receipt = find_fiscal_receipt!(tenant_id)
      provider_data = normalize_payload(params[:provider_data])

      new_status = params[:status].to_s
      unless FiscalReceipt.statuses.key?(new_status)
        return render json: { error: "invalid fiscal receipt status" }, status: :unprocessable_entity
      end

      receipt.with_lock do
        receipt.status = new_status
        receipt.ofd_receipt_id = params[:ofd_receipt_id] if params[:ofd_receipt_id].present?
        receipt.error_message = params[:error_message] if params.key?(:error_message)
        receipt.sent_at = Time.current if new_status == "sent" && receipt.sent_at.blank?
        receipt.confirmed_at = Time.current if new_status == "confirmed" && receipt.confirmed_at.blank?

        if provider_data.present?
          data = receipt.receipt_data.presence || {}
          receipt.receipt_data = data.merge("provider_data" => provider_data)
        end

        receipt.save!
      end

      audit_event(
        state: "processed",
        callback_type: "fiscal_receipt",
        tenant_id: tenant_id,
        record_id: receipt.id,
        details: { status: receipt.status, ofd_receipt_id: receipt.ofd_receipt_id }
      )

      render json: { ok: true, fiscal_receipt_id: receipt.id, status: receipt.status }
    rescue ActiveRecord::RecordNotFound
      audit_event(state: "failed", callback_type: "fiscal_receipt", tenant_id: params[:tenant_id], details: { error: "fiscal receipt not found" })
      render json: { error: "fiscal receipt not found" }, status: :not_found
    end

    private

    def prepare_callback_context
      @callback_raw_body = request.raw_post.to_s
      @callback_timestamp = request.headers["X-Callback-Timestamp"].to_s
      @callback_signature = request.headers["X-Callback-Signature"].to_s
      @callback_idempotency_key = request.headers["X-Idempotency-Key"].presence || params[:idempotency_key].presence
      @callback_payload_hash = Digest::SHA256.hexdigest(@callback_raw_body)
      @idempotency_cache_key = @callback_idempotency_key.present? ? "callbacks:idempotency:#{@callback_idempotency_key}" : nil
    end

    def authenticate_callback!
      expected = ENV["CALLBACK_SHARED_TOKEN"].to_s
      return if expected.blank?
      return if request.headers["X-Callback-Token"].to_s == expected

      audit_event(state: "rejected", callback_type: action_name, tenant_id: params[:tenant_id], details: { reason: "token auth failed" })
      render json: { error: "unauthorized callback" }, status: :unauthorized
    end

    def authenticate_callback_hmac!
      secret = ENV["CALLBACK_SHARED_SECRET"].to_s
      return if secret.blank?

      if @callback_timestamp.blank? || @callback_signature.blank?
        audit_event(state: "rejected", callback_type: action_name, tenant_id: params[:tenant_id], details: { reason: "missing signature headers" })
        return render json: { error: "missing callback signature headers" }, status: :unauthorized
      end

      signed_payload = "#{@callback_timestamp}.#{@callback_raw_body}"
      expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)

      unless ActiveSupport::SecurityUtils.secure_compare(expected_signature, @callback_signature)
        audit_event(state: "rejected", callback_type: action_name, tenant_id: params[:tenant_id], details: { reason: "invalid signature" })
        return render json: { error: "invalid callback signature" }, status: :unauthorized
      end
    end

    def enforce_anti_replay!
      secret = ENV["CALLBACK_SHARED_SECRET"].to_s
      return if secret.blank?

      timestamp = @callback_timestamp.to_i
      now = Time.current.to_i
      max_age = ENV.fetch("CALLBACK_MAX_AGE_SECONDS", "300").to_i

      if timestamp <= 0 || (now - timestamp).abs > max_age
        audit_event(state: "rejected", callback_type: action_name, tenant_id: params[:tenant_id], details: { reason: "stale timestamp", timestamp: @callback_timestamp })
        return render json: { error: "stale callback timestamp" }, status: :unauthorized
      end
    end

    def enforce_idempotency!
      secret = ENV["CALLBACK_SHARED_SECRET"].to_s
      require_key = secret.present? || ENV["CALLBACK_REQUIRE_IDEMPOTENCY"] == "1"
      if require_key && @callback_idempotency_key.blank?
        audit_event(state: "rejected", callback_type: action_name, tenant_id: params[:tenant_id], details: { reason: "missing idempotency key" })
        return render json: { error: "missing idempotency key" }, status: :unprocessable_entity
      end

      return if @idempotency_cache_key.blank?

      # BUG-019 FIX: Используем только Redis/Solid Cache. Файловый fallback удалён —
      # он не работает в multi-pod окружении (каждый pod имеет свою файловую систему).
      existing = Rails.cache.read(@idempotency_cache_key)
      if existing.present?
        audit_event(state: "duplicate", callback_type: action_name, tenant_id: params[:tenant_id], details: { existing: existing })
        return render json: { ok: true, duplicate: true, idempotency_key: @callback_idempotency_key }, status: :ok
      end

      cache_payload = {
        state: "processing",
        at: Time.current.to_i,
        action: action_name,
        payload_hash: @callback_payload_hash
      }
      Rails.cache.write(@idempotency_cache_key, cache_payload, expires_in: 24.hours)
    end

    def find_payment!(tenant_id)
      scope = Payment.where(tenant_id: tenant_id)
      if params[:payment_id].present?
        scope.find(params[:payment_id])
      elsif params[:provider_payment_id].present?
        scope.find_by!(provider_payment_id: params[:provider_payment_id])
      else
        raise ActiveRecord::RecordNotFound
      end
    end

    def find_fiscal_receipt!(tenant_id)
      scope = FiscalReceipt.where(tenant_id: tenant_id)
      if params[:fiscal_receipt_id].present?
        scope.find(params[:fiscal_receipt_id])
      elsif params[:ofd_receipt_id].present?
        scope.find_by!(ofd_receipt_id: params[:ofd_receipt_id])
      else
        raise ActiveRecord::RecordNotFound
      end
    end

    def normalize_payload(value)
      return {} if value.blank?
      return value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
      return value.to_h if value.respond_to?(:to_h)

      {}
    end

    def audit_event(state:, callback_type:, tenant_id:, record_id: nil, details: {})
      payload = {
        event: "callback_event",
        state: state,
        callback_type: callback_type,
        tenant_id: tenant_id,
        record_id: record_id,
        idempotency_key: @callback_idempotency_key,
        payload_hash: @callback_payload_hash,
        request_id: request.request_id,
        ip: request.remote_ip,
        at: Time.current.iso8601,
        details: details
      }

      Rails.logger.info(payload.to_json)

      log_path = Rails.root.join("log", "callback_audit.log")
      File.open(log_path, "a") { |f| f.puts(payload.to_json) }

      return if @idempotency_cache_key.blank?
      return unless state.in?(%w[processed failed])

      Rails.cache.write(
        @idempotency_cache_key,
        {
          state: state,
          at: Time.current.to_i,
          action: callback_type,
          payload_hash: @callback_payload_hash,
          details: details
        },
        expires_in: 24.hours
      )
    rescue StandardError => e
      Rails.logger.error({ event: "callback_audit_write_failed", error: e.message }.to_json)
    end

  end
end

