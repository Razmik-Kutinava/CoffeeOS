# frozen_string_literal: true

module Payments
  # #75: velocity antifraud для попыток привязки (окно 15 мин).
  class BindingVelocity
    WINDOW = 15.minutes
    LIMIT_METHOD_HASH = 5
    LIMIT_PHONE = 10
    LIMIT_DEVICE_OR_IP = 20
    LIMIT_BIN = 30

    Result = Struct.new(:allowed?, :reason, keyword_init: true)

    def self.check!(method_type:, method_hash: nil, phone: nil, device_fingerprint: nil, ip: nil, bin: nil)
      new.check!(
        method_type: method_type,
        method_hash: method_hash,
        phone: phone,
        device_fingerprint: device_fingerprint,
        ip: ip,
        bin: bin
      )
    end

    def check!(method_type:, method_hash: nil, phone: nil, device_fingerprint: nil, ip: nil, bin: nil)
      since = WINDOW.ago
      scope = CardBindingAttempt.where("created_at >= ?", since)

      if method_hash.present? && scope.where(method_hash: method_hash).count >= LIMIT_METHOD_HASH
        return deny
      end

      digest = CardBindingAttempt.phone_digest_for(phone)
      if digest.present? && scope.where(phone_digest: digest).count >= LIMIT_PHONE
        return deny
      end

      if device_fingerprint.present? && scope.where(device_fingerprint: device_fingerprint).count >= LIMIT_DEVICE_OR_IP
        return deny
      end

      if ip.present? && scope.where(ip: ip).count >= LIMIT_DEVICE_OR_IP
        return deny
      end

      if method_type.to_s == "card" && bin.present? && scope.where(bin: bin, method_type: "card").count >= LIMIT_BIN
        return deny
      end

      Result.new(allowed?: true, reason: nil)
    end

    private

    def deny
      Result.new(allowed?: false, reason: "rate_limited")
    end
  end
end
