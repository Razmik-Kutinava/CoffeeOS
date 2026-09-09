# frozen_string_literal: true

module Shop
  # Digest lookup + tenant match for server X-Shop-Api-Key (V3-SEC-SHOP-API-KEYS).
  class ApiKeyAuthenticator
    class Unauthorized < StandardError; end

    def self.call!(raw_key:, tenant_id:)
      new(raw_key: raw_key, tenant_id: tenant_id).call!
    end

    def initialize(raw_key:, tenant_id:)
      @raw_key = raw_key.to_s
      @tenant_id = tenant_id
    end

    def call!
      raise Unauthorized if @raw_key.blank?

      record = find_usable_by_digest
      if record
        allow!(record)
        return record
      end

      allow_env_fallback!
    end

    private

    def find_usable_by_digest
      digest = ShopApiKey.digest(@raw_key)
      Rls::GucContext.with_shop_api_key_lookup do
        ShopApiKey.usable.find_by(token_digest: digest)
      end
    end

    def allow!(record)
      if record.global_ops?
        touch_last_used(record)
        return
      end

      raise Unauthorized if @tenant_id.blank?
      raise Unauthorized unless ActiveSupport::SecurityUtils.secure_compare(
        record.tenant_id.to_s,
        @tenant_id.to_s
      )

      touch_last_used(record)
    end

    def allow_env_fallback!
      raise Unauthorized unless env_fallback_enabled?

      expected = ENV["SHOP_API_KEY"].to_s
      raise Unauthorized if expected.blank?
      raise Unauthorized unless ActiveSupport::SecurityUtils.secure_compare(@raw_key, expected)

      Rails.logger.warn(
        "[Shop::ApiKeyAuthenticator] ENV SHOP_API_KEY fallback as global_ops — " \
        "seed per-tenant keys then set SHOP_API_KEY_FALLBACK=0"
      )
      :env_global_ops_fallback
    end

    def env_fallback_enabled?
      return false if ENV["SHOP_API_KEY_FALLBACK"].to_s == "0"

      ENV["SHOP_API_KEY"].to_s.present?
    end

    def touch_last_used(record)
      # Throttle: at most once per minute to avoid write noise on every request.
      return if record.last_used_at.present? && record.last_used_at > 1.minute.ago

      Rls::GucContext.with_shop_api_key_lookup do
        record.update_column(:last_used_at, Time.current)
      end
    rescue StandardError => e
      Rails.logger.debug { "[Shop::ApiKeyAuthenticator] last_used_at skip: #{e.class}" }
    end
  end
end
