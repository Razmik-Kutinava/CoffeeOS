# frozen_string_literal: true

module Devices
  # Генерация device_token и срока действия (ENV DEVICE_TOKEN_TTL_DAYS).
  class TokenCredentials
    def self.generate
      SecureRandom.hex(24)
    end

    # nil = без срока (legacy / ENV не задан или <= 0).
    def self.ttl_days
      days = ENV.fetch("DEVICE_TOKEN_TTL_DAYS", "").to_s.strip
      return nil if days.blank?

      ttl = days.to_i
      ttl.positive? ? ttl : nil
    end

    def self.rotate_warn_days
      days = ENV.fetch("DEVICE_TOKEN_ROTATE_WARN_DAYS", "14").to_s.strip.to_i
      days.positive? ? days : 14
    end

    def self.default_expires_at
      ttl = ttl_days
      return nil unless ttl

      ttl.days.from_now
    end

    def self.policy_description
      ttl = ttl_days
      if ttl
        "Новые и перевыпущенные токены действуют #{ttl} дн. (ENV DEVICE_TOKEN_TTL_DAYS)."
      else
        "Срок токенов не ограничен — DEVICE_TOKEN_TTL_DAYS не задан или ≤ 0."
      end
    end

    def self.apply_attributes!(device:)
      device.device_token = generate
      device.token_expires_at = default_expires_at
      device.is_active = true
      clear_expiry_cron_metadata!(device)
      device
    end

    def self.clear_expiry_cron_metadata!(device)
      meta = (device.metadata || {}).except(
        Devices::ExpiringTokensProcessor::METADATA_WARNED_AT,
        Devices::ExpiringTokensProcessor::METADATA_DEACTIVATED_AT,
        Devices::ExpiringTokensProcessor::METADATA_DEACTIVATED_BY
      )
      device.metadata = meta
    end

    def self.assign_new!(device:)
      apply_attributes!(device: device)
      device.save!
      device.device_token
    end
  end
end
