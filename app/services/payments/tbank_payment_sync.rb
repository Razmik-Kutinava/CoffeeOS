# frozen_string_literal: true

module Payments
  # Синхронизация статуса платежа и RebillId через GetState (B1.12).
  # Вызывается из finalize, когда webhook задержался или не передал Pan/RebillId.
  class TbankPaymentSync
    DEFAULT_REBILL_RETRIES = Integer(ENV.fetch("TBANK_REBILL_SYNC_RETRIES", "5"))

    def self.rebill_pause_seconds
      Float(ENV.fetch("TBANK_REBILL_SYNC_PAUSE_SEC", "1"))
    end

    def self.sync_order!(order:, adapter: nil)
      payment = resolve_payment(order)
      return false unless payment

      new(payment: payment, adapter: adapter).sync!
    end

    # FA/webhook CONFIRMED без RebillId — несколько GetState с паузой (Фаза 3.3 UserCards).
    def self.sync_order_for_rebill!(order:, adapter: nil, retries: nil, pause: nil)
      payment = resolve_payment(order)
      return false unless payment

      new(payment: payment, adapter: adapter).sync_for_rebill!(retries: retries, pause: pause)
    end

    def self.resolve_payment(order)
      payment = order.payments.where(provider: "tbank").order(created_at: :desc).first
      payment ||= order.payments
        .where.not(provider_payment_id: [ nil, "" ])
        .order(created_at: :desc)
        .first
      payment
    end

    def initialize(payment:, adapter: nil)
      @payment = payment
      @adapter = adapter
    end

    def sync!
      provider_id = @payment.provider_payment_id.to_s.presence
      return false if provider_id.blank?

      state = fetch_state!(provider_id)
      return false unless state

      apply_state!(state)
      true
    rescue TbankAdapter::Error => e
      Rails.logger.warn("[TbankPaymentSync] payment=#{@payment.id} #{e.message}")
      false
    end

    def sync_for_rebill!(retries: nil, pause: nil)
      provider_id = @payment.provider_payment_id.to_s.presence
      return false if provider_id.blank?
      return true if rebill_already_persisted?

      pause_sec = pause.nil? ? self.class.rebill_pause_seconds : pause.to_f
      max_attempts = [ (retries || DEFAULT_REBILL_RETRIES).to_i, 1 ].max

      max_attempts.times do |attempt|
        state = fetch_state!(provider_id)
        if state
          apply_state!(state)
          return true if rebill_persisted_from_state?(state)
        end

        sleep(pause_sec) if attempt < max_attempts - 1 && rebill_still_needed?
      end

      log_missing_rebill_if_needed
      false
    rescue TbankAdapter::Error => e
      Rails.logger.warn("[TbankPaymentSync] payment=#{@payment.id} #{e.message}")
      log_missing_rebill_if_needed
      false
    end

    private

    def fetch_state!(provider_id)
      response = adapter.get_payment_state(payment_id: provider_id)
      return unless response.is_a?(Hash) && response["Success"]

      # ТЗ Шаг 2: при AUTHORIZED делаем auto Confirm, чтобы перейти к CONFIRMED.
      if response["Status"].to_s.upcase == "AUTHORIZED"
        confirm = adapter.confirm_payment(payment_id: provider_id)
        return confirm if confirm.is_a?(Hash) && confirm["Success"]
      end

      response
    end

    def apply_state!(state)
      tbank_status = state["Status"].to_s
      our_status = TbankAdapter.map_status(tbank_status)
      provider_id = state["PaymentId"].to_s.presence || @payment.provider_payment_id.to_s

      if our_status && @payment.status != our_status
        Callbacks::PaymentStatusUpdater.new(
          payment: @payment,
          new_status: our_status,
          provider_data: state.except("Token", "Password", "Success"),
          provider_payment_id: provider_id,
          note: "Т-Банк GetState: #{tbank_status}"
        ).call!
        @payment.reload
      elsif state["RebillId"].to_s.present? || rebill_still_needed?
        merge_provider_data!(state, provider_id)
      end

      persist_card_if_needed!(state, tbank_status)
    end

    def merge_provider_data!(state, provider_id)
      data = (@payment.provider_data.is_a?(Hash) ? @payment.provider_data : {}).dup
      save_card = data["save_card"]
      merged = data.merge(state.except("Token", "Password", "Success"))
      # ErrorCode/Message оставляем — inline FSM (1051 «Недостаточно средств») читает их из status API.
      merged["save_card"] = save_card unless save_card.nil?
      merged["PaymentId"] = provider_id if provider_id.present?
      @payment.update_columns(provider_data: merged)
      @payment.reload
    end

    def persist_card_if_needed!(state, tbank_status)
      return unless tbank_status.upcase == "CONFIRMED"
      return if state["RebillId"].to_s.blank?
      return unless Payments::SavedCardStore.allowed_for?(@payment)

      payload = state.merge(
        "Status" => tbank_status,
        "OrderId" => @payment.order_id.to_s,
        "PaymentId" => state["PaymentId"].to_s.presence || @payment.provider_payment_id.to_s
      )
      Payments::SavedCardStore.persist_from_tbank!(payment: @payment, payload: payload)
    end

    def rebill_already_persisted?
      return false unless Payments::SavedCardStore.allowed_for?(@payment)

      rebill_id = @payment.provider_data.is_a?(Hash) ? @payment.provider_data["RebillId"].to_s : ""
      return false if rebill_id.blank?

      MobilePaymentMethod.exists?(
        customer_id: @payment.order.customer_id,
        card_token: rebill_id,
        payment_type: "card"
      )
    end

    def rebill_persisted_from_state?(state)
      return false unless state["Status"].to_s.upcase == "CONFIRMED"
      return false if state["RebillId"].to_s.blank?
      return false unless Payments::SavedCardStore.allowed_for?(@payment.reload)

      MobilePaymentMethod.exists?(
        customer_id: @payment.order.customer_id,
        card_token: state["RebillId"].to_s,
        payment_type: "card"
      )
    end

    def rebill_still_needed?
      return false unless Payments::SavedCardStore.allowed_for?(@payment.reload)

      data = @payment.provider_data
      data = {} unless data.is_a?(Hash)
      data["RebillId"].to_s.blank?
    end

    def log_missing_rebill_if_needed
      return unless rebill_still_needed?

      Rails.logger.warn(
        "[UserCards] missing RebillId payment_id=#{@payment.id} " \
        "provider_payment_id=#{@payment.provider_payment_id}"
      )
    end

    def adapter
      @adapter ||= TbankAdapter.new
    end
  end
end
