# frozen_string_literal: true

module Shop
  class EmailVerificationSession
    KEY = :shop_email_verified_by_tenant
    DEFAULT_TTL = 24.hours

    def self.normalize(email)
      email.to_s.strip.downcase
    end

    def self.verified_email(session, tenant_id)
      bucket = session[KEY]
      return nil unless bucket.is_a?(Hash)

      entry = bucket[tenant_id.to_s]
      return nil unless entry.is_a?(Hash)

      email = normalize(entry["email"])
      return nil if email.blank?

      expires_at = Time.zone.parse(entry["expires_at"].to_s)
      return nil if expires_at.nil? || expires_at < Time.current

      email
    rescue ArgumentError
      nil
    end

    def self.mark_verified!(session, tenant_id, email, ttl: DEFAULT_TTL)
      bucket = session[KEY].is_a?(Hash) ? session[KEY].dup : {}
      bucket[tenant_id.to_s] = {
        "email" => normalize(email),
        "expires_at" => ttl.from_now.iso8601
      }
      session[KEY] = bucket
    end

    def self.clear!(session, tenant_id)
      bucket = session[KEY]
      return unless bucket.is_a?(Hash)

      bucket = bucket.dup
      bucket.delete(tenant_id.to_s)
      session[KEY] = bucket
    end
  end
end
