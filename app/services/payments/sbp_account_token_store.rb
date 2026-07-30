# frozen_string_literal: true

module Payments
  # #34: AccountToken СБП в mobile_payment_methods (payment_type=sbp).
  # RequestKey → bank_card_id для идемпотентности без DDL.
  class SbpAccountTokenStore
    REQUEST_CACHE_TTL = 30.days

    def self.persist!(customer_id:, account_token:, request_key:)
      new.persist!(customer_id: customer_id, account_token: account_token, request_key: request_key)
    end

    def self.handle_charge_outcome!(customer_id:, account_token:, fatal:)
      new.handle_charge_outcome!(customer_id: customer_id, account_token: account_token, fatal: fatal)
    end

    def persist!(customer_id:, account_token:, request_key:)
      raise ArgumentError, "customer_id blank" if customer_id.blank?
      raise ArgumentError, "account_token blank" if account_token.blank?

      rk = request_key.to_s.presence
      cache_key = rk.present? ? "tbank:sbp_account:#{rk}" : nil

      if cache_key && (cached_id = Rails.cache.read(cache_key)).present?
        existing = MobilePaymentMethod.find_by(id: cached_id, customer_id: customer_id, payment_type: "sbp")
        return existing if existing
      end

      MobilePaymentMethod.transaction do
        row = if rk.present?
          MobilePaymentMethod.find_by(customer_id: customer_id, payment_type: "sbp", bank_card_id: rk)
        end
        row ||= MobilePaymentMethod.find_by(
          customer_id: customer_id,
          payment_type: "sbp",
          card_token: account_token.to_s
        )
        row ||= MobilePaymentMethod.new(customer_id: customer_id, payment_type: "sbp")

        row.card_token = account_token.to_s
        row.bank_card_id = rk if rk.present?
        row.card_masked = "СБП"
        row.card_brand = "SBP"
        row.is_active = true
        row.last_used_at = Time.current
        row.save!

        Rails.cache.write(cache_key, row.id, expires_in: REQUEST_CACHE_TTL) if cache_key
        row
      end
    end

    def handle_charge_outcome!(customer_id:, account_token:, fatal:)
      return unless fatal

      MobilePaymentMethod
        .where(customer_id: customer_id, payment_type: "sbp", card_token: account_token.to_s)
        .update_all(is_active: false)
    end
  end
end
