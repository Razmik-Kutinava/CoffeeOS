# frozen_string_literal: true

module Payments
  # Сохранение RebillId (bank_token) и masked PAN после успешного webhook Т-Банка.
  class SavedCardStore
    def self.persist_from_tbank!(payment:, payload:)
      new(payment: payment, payload: payload).call!
    end

    def initialize(payment:, payload:)
      @payment = payment
      @payload = payload.stringify_keys
    end

    def call!
      return unless @payload["Status"].to_s.upcase == "CONFIRMED"

      rebill_id = @payload["RebillId"].to_s.presence
      return if rebill_id.blank?

      order = @payment.order
      customer_id = order&.customer_id
      return if customer_id.blank?

      masked = @payload["Pan"].to_s.presence
      return if masked.blank?

      brand = infer_brand(masked)

      MobilePaymentMethod.transaction do
        card = MobilePaymentMethod.find_or_initialize_by(
          customer_id: customer_id,
          card_token: rebill_id,
          payment_type: "card"
        )
        card.card_masked = masked
        card.card_brand = brand
        card.is_active = true
        card.last_used_at = Time.current
        card.save!

        MobilePaymentMethod
          .where(customer_id: customer_id, payment_type: "card")
          .where.not(id: card.id)
          .update_all(is_default: false)

        card.update!(is_default: true)
        card
      end
    end

    private

    def infer_brand(masked_pan)
      digit = masked_pan.gsub(/\D/, "")[0]
      case digit
      when "4" then "Visa"
      when "5" then "Mastercard"
      when "2" then "MIR"
      else "Card"
      end
    end
  end
end
