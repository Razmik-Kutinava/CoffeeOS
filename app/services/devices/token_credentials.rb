# frozen_string_literal: true

module Devices
  # Генерация device_token и срока действия (ENV DEVICE_TOKEN_TTL_DAYS).
  class TokenCredentials
    def self.generate
      SecureRandom.hex(24)
    end

    # nil = без срока (legacy / ENV не задан или <= 0).
    def self.default_expires_at
      days = ENV.fetch("DEVICE_TOKEN_TTL_DAYS", "").to_s.strip
      return nil if days.blank?

      ttl_days = days.to_i
      return nil if ttl_days <= 0

      ttl_days.days.from_now
    end

    def self.apply_attributes!(device:)
      device.device_token = generate
      device.token_expires_at = default_expires_at
      device.is_active = true
      device
    end

    def self.assign_new!(device:)
      apply_attributes!(device: device)
      device.save!
      device.device_token
    end
  end
end
