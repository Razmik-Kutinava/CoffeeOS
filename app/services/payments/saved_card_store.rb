# frozen_string_literal: true

module Payments
  # Upsert UserCards (mobile_payment_methods) после CONFIRMED + RebillId.
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
      brand = normalize_brand(@payload)
      bank_card_id = @payload["CardId"].to_s.presence
      exp_date = normalize_exp_date(@payload["ExpDate"].to_s.presence)

      MobilePaymentMethod.transaction do
        card = MobilePaymentMethod.find_by(
          customer_id: customer_id,
          card_token: rebill_id,
          payment_type: "card"
        )
        # Дубликат по pan + exp_date (extreme ТЗ) — обновляем RebillId, не создаём второй ряд.
        if card.nil? && masked.present? && exp_date.present?
          card = MobilePaymentMethod.find_by(
            customer_id: customer_id,
            card_masked: masked,
            card_expires_at: exp_date,
            payment_type: "card"
          )
        end
        card ||= MobilePaymentMethod.new(customer_id: customer_id, payment_type: "card")

        card.card_token = rebill_id
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
      return "*#{digits[-4..]}" if digits.length >= 4

      masked
    end

    def normalize_exp_date(raw)
      return if raw.blank?

      digits = raw.gsub(/\D/, "")
      return "#{digits[0, 2]}/#{digits[2, 2]}" if digits.length == 4
      return raw if raw.match?(%r{\A\d{2}/\d{2}\z})

      raw
    end

    def normalize_brand(payload)
      explicit = payload["CardType"].to_s.presence || payload["PanExtra"].to_s.presence
      if explicit.present?
        up = explicit.upcase
        return "MIR" if up.include?("MIR")
        return "VISA" if up.include?("VISA")
        return "MASTERCARD" if up.include?("MASTER") || up.include?("MC")
      end

      digit = extract_masked_pan(payload).gsub(/\D/, "")[0]
      case digit
      when "4" then "VISA"
      when "5" then "MASTERCARD"
      when "2" then "MIR"
      else "CARD"
      end
    end
  end
end
