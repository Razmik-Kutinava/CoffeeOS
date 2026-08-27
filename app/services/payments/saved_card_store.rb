# frozen_string_literal: true

module Payments
  # Upsert UserCards (mobile_payment_methods) после CONFIRMED + RebillId.
  class SavedCardStore
    # Стабильный keyed hash от CardId эквайринга (глобальная идентичность карты).
    # Pepper: CARD_HASH_PEPPER / credentials — не ротировать вместе с SECRET_KEY_BASE.
    def self.card_hash_for(bank_card_id)
      id = bank_card_id.to_s.presence
      return if id.blank?

      OpenSSL::HMAC.hexdigest(
        "SHA256",
        card_hash_pepper,
        "mobile_payment_methods.card_hash.v1:#{id}"
      )
    end

    def self.card_hash_pepper
      ENV["CARD_HASH_PEPPER"].presence ||
        Rails.application.credentials.dig(:payments, :card_hash_pepper).presence ||
        Rails.application.secret_key_base
    end

    def self.persist_from_tbank!(payment:, payload:)
      new(payment: payment, payload: payload).call!
    end

    # Шаг 6: webhook/GetState пишут карту только если гость просил save_card.
    # Ключ пишется в payment.provider_data["save_card"] из NewCardPaymentService.
    # Legacy / one-click без ключа → true (idempotent upsert существующей карты).
    def self.allowed_for?(payment)
      data = payment&.provider_data
      data = {} unless data.is_a?(Hash)
      ActiveModel::Type::Boolean.new.cast(data.fetch("save_card", true))
    end

    def initialize(payment:, payload:)
      @payment = payment
      @payload = payload.stringify_keys
    end

    def call!
      return unless @payload["Status"].to_s.upcase == "CONFIRMED"
      return unless self.class.allowed_for?(@payment)

      rebill_id = @payload["RebillId"].to_s.presence
      return if rebill_id.blank?

      order = @payment.order
      customer_id = order&.customer_id
      return if customer_id.blank?

      masked = extract_masked_pan(@payload)
      brand = normalize_brand(@payload)
      bank_card_id = @payload["CardId"].to_s.presence
      card_hash = self.class.card_hash_for(bank_card_id)
      exp_date = normalize_exp_date(@payload["ExpDate"].to_s.presence)

      if foreign_active_binding?(customer_id, card_hash: card_hash, bank_card_id: bank_card_id)
        log_binding_rejected
        return nil
      end

      MobilePaymentMethod.transaction do
        card = find_existing_card(customer_id, rebill_id, masked, exp_date, card_hash, bank_card_id)
        card ||= MobilePaymentMethod.new(customer_id: customer_id, payment_type: "card")

        card.card_token = rebill_id
        card.card_masked = masked
        card.card_brand = brand
        card.bank_card_id = bank_card_id if bank_card_id
        card.card_hash = card_hash if card_hash
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
    rescue ActiveRecord::RecordNotUnique
      log_binding_rejected
      nil
    end

    private

    def find_existing_card(customer_id, rebill_id, masked, exp_date, card_hash, bank_card_id)
      card = MobilePaymentMethod.find_by(
        customer_id: customer_id,
        card_token: rebill_id,
        payment_type: "card"
      )
      if card.nil? && card_hash.present?
        card = MobilePaymentMethod.find_by(
          customer_id: customer_id,
          card_hash: card_hash,
          payment_type: "card"
        )
      end
      if card.nil? && bank_card_id.present?
        card = MobilePaymentMethod.find_by(
          customer_id: customer_id,
          bank_card_id: bank_card_id,
          payment_type: "card"
        )
      end
      # pan+exp только если не подменяем чужой CardId через коллизию last4.
      if card.nil? && masked.present? && exp_date.present?
        candidate = MobilePaymentMethod.find_by(
          customer_id: customer_id,
          card_masked: masked,
          card_expires_at: exp_date,
          payment_type: "card"
        )
        if candidate && (bank_card_id.blank? || candidate.bank_card_id.blank? || candidate.bank_card_id == bank_card_id)
          card = candidate
        end
      end
      card
    end

    def foreign_active_binding?(customer_id, card_hash:, bank_card_id:)
      scope = MobilePaymentMethod
        .where(is_active: true, payment_type: "card")
        .where.not(customer_id: customer_id)

      return true if card_hash.present? && scope.where(card_hash: card_hash).exists?
      return true if bank_card_id.present? && scope.where(bank_card_id: bank_card_id).exists?

      false
    end

    def log_binding_rejected
      Rails.logger.info("[SavedCardStore] card_binding_rejected")
    end

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

      # BIN только из полного/маскированного PAN; last4 (*5953) не угадываем.
      raw = payload["Pan"].presence || payload["MaskedPan"].presence || ""
      digits = raw.to_s.gsub(/\D/, "")
      return "CARD" if digits.length <= 4

      case digits[0]
      when "4" then "VISA"
      when "5" then "MASTERCARD"
      when "2" then "MIR"
      else "CARD"
      end
    end
  end
end
