# frozen_string_literal: true

module Payments
  # #34 + #75: AccountToken СБП в mobile_payment_methods; стабильный method_hash + unique active.
  class SbpAccountTokenStore
    REQUEST_CACHE_TTL = 30.days
    BLOCKED = :blocked_method_taken
    RATE_LIMITED = :rate_limited

    def self.method_hash_for(account_token)
      token = account_token.to_s.presence
      return if token.blank?

      OpenSSL::HMAC.hexdigest(
        "SHA256",
        SavedCardStore.card_hash_pepper,
        "mobile_payment_methods.sbp_method_hash.v1:#{token}"
      )
    end

    def self.persist!(customer_id:, account_token:, request_key:, ip: nil, device_fingerprint: nil)
      new.persist!(
        customer_id: customer_id,
        account_token: account_token,
        request_key: request_key,
        ip: ip,
        device_fingerprint: device_fingerprint
      )
    end

    def self.handle_charge_outcome!(customer_id:, account_token:, fatal:)
      new.handle_charge_outcome!(customer_id: customer_id, account_token: account_token, fatal: fatal)
    end

    def persist!(customer_id:, account_token:, request_key:, ip: nil, device_fingerprint: nil)
      raise ArgumentError, "customer_id blank" if customer_id.blank?
      raise ArgumentError, "account_token blank" if account_token.blank?

      rk = request_key.to_s.presence
      cache_key = rk.present? ? "tbank:sbp_account:#{rk}" : nil
      method_hash = self.class.method_hash_for(account_token)
      customer = MobileCustomer.find_by(id: customer_id)

      if cache_key && (cached_id = Rails.cache.read(cache_key)).present?
        existing = MobilePaymentMethod.find_by(id: cached_id, customer_id: customer_id, payment_type: "sbp")
        return existing if existing
      end

      if foreign_active_binding?(customer_id, method_hash: method_hash)
        log_binding_rejected
        record_attempt!(customer: customer, method_hash: method_hash, result: "blocked_method_taken",
                        ip: ip, device_fingerprint: device_fingerprint)
        return BLOCKED
      end

      # BIN velocity не применяется к СБП.
      velocity = BindingVelocity.check!(
        method_type: "sbp",
        method_hash: method_hash,
        phone: customer&.phone,
        device_fingerprint: device_fingerprint,
        ip: ip,
        bin: nil
      )
      unless velocity.allowed?
        record_attempt!(customer: customer, method_hash: method_hash, result: "rate_limited",
                        reason: velocity.reason, ip: ip, device_fingerprint: device_fingerprint)
        return RATE_LIMITED
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
        if row.nil? && method_hash.present?
          row = MobilePaymentMethod.find_by(
            customer_id: customer_id,
            payment_type: "sbp",
            card_hash: method_hash
          )
        end
        row ||= MobilePaymentMethod.new(customer_id: customer_id, payment_type: "sbp")

        row.card_token = account_token.to_s
        row.bank_card_id = rk if rk.present?
        row.card_hash = method_hash if method_hash
        row.card_masked = "СБП"
        row.card_brand = "SBP"
        row.is_active = true
        row.last_used_at = Time.current
        row.save!

        Rails.cache.write(cache_key, row.id, expires_in: REQUEST_CACHE_TTL) if cache_key
        record_attempt!(customer: customer, method_hash: method_hash, result: "ok",
                        ip: ip, device_fingerprint: device_fingerprint)
        row
      end
    rescue ActiveRecord::RecordNotUnique
      log_binding_rejected
      record_attempt!(customer: customer, method_hash: method_hash, result: "blocked_method_taken",
                      ip: ip, device_fingerprint: device_fingerprint)
      BLOCKED
    end

    def handle_charge_outcome!(customer_id:, account_token:, fatal:)
      return unless fatal

      MobilePaymentMethod
        .where(customer_id: customer_id, payment_type: "sbp", card_token: account_token.to_s)
        .update_all(is_active: false)
    end

    private

    def foreign_active_binding?(customer_id, method_hash:)
      return false if method_hash.blank?

      MobilePaymentMethod
        .where(is_active: true, payment_type: "sbp", card_hash: method_hash)
        .where.not(customer_id: customer_id)
        .exists?
    end

    def record_attempt!(customer:, method_hash:, result:, reason: nil, ip: nil, device_fingerprint: nil)
      CardBindingAttempt.record!(
        method_type: "sbp",
        method_hash: method_hash,
        phone: customer&.phone,
        account_id: customer&.id,
        ip: ip,
        device_fingerprint: device_fingerprint,
        result: result,
        reason: reason,
        is_growth_event: false
      )
    rescue StandardError => e
      Rails.logger.warn("[SbpAccountTokenStore] attempt log failed: #{e.class}: #{e.message}")
    end

    def log_binding_rejected
      Rails.logger.info("[SbpAccountTokenStore] method_binding_rejected")
    end
  end
end
