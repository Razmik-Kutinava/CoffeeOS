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

      masked = extract_masked_pan(@payload)
      brand = infer_brand(masked)
      bank_card_id = @payload["CardId"].to_s.presence
      exp_date = @payload["ExpDate"].to_s.presence

      MobilePaymentMethod.transaction do
        card = MobilePaymentMethod.find_or_initialize_by(
          customer_id: customer_id,
          card_token: rebill_id,
          payment_type: "card"
        )
        card.card_masked = masked
        card.card_brand = brand
        card.bank_card_id = bank_card_id if bank_card_id
        card.card_expires_at = exp_date if exp_date
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

    def extract_masked_pan(payload)
      %w[Pan MaskedPan].each do |key|
        val = payload[key].to_s.presence
        return format_pan_display(val) if val
      end

      "•••• ****"
    end

    def format_pan_display(masked)
      digits = masked.gsub(/\D/, "")
      return "*#{digits[-4..]}" if digits.length >= 4 && !masked.include?("*")

      masked
    end

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
