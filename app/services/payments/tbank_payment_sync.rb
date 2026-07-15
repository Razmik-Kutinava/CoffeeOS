# frozen_string_literal: true

module Payments
  # Синхронизация статуса платежа и RebillId через GetState (B1.12).
  # Вызывается из finalize, когда webhook задержался или не передал Pan/RebillId.
  class TbankPaymentSync
    def self.sync_order!(order:, adapter: nil)
      payment = order.payments.where(provider: "tbank").order(created_at: :desc).first
      payment ||= order.payments
        .where.not(provider_payment_id: [nil, ""])
        .order(created_at: :desc)
        .first
      return false unless payment

      new(payment: payment, adapter: adapter).sync!
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

    private

    def fetch_state!(provider_id)
      response = adapter.get_payment_state(payment_id: provider_id)
      response if response.is_a?(Hash) && response["Success"]
    end

    def apply_state!(state)
      tbank_status = state["Status"].to_s
      our_status = TbankAdapter.map_status(tbank_status)
      provider_id = state["PaymentId"].to_s.presence || @payment.provider_payment_id.to_s

      if our_status && @payment.status != our_status
        Callbacks::PaymentStatusUpdater.new(
          payment: @payment,
          new_status: our_status,
          provider_data: state.except("Token", "Password", "Success", "ErrorCode", "Message"),
          provider_payment_id: provider_id,
          note: "Т-Банк GetState: #{tbank_status}"
        ).call!
        @payment.reload
      end

      persist_card_if_needed!(state, tbank_status)
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

    def adapter
      @adapter ||= TbankAdapter.new
    end
  end
end
