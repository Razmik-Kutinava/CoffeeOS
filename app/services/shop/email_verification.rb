# frozen_string_literal: true

module Shop
  # Подтверждение email на витрине: Rails session + Postgres (per tenant + browser session).
  # DB даёт общий источник между web-инстансами без Redis.
  class EmailVerification
    def self.verified_email(session:, tenant_id:, session_id: nil)
      from_session = EmailVerificationSession.verified_email(session, tenant_id)
      return from_session if from_session.present?

      record = ShopEmailVerification.active_for(tenant_id: tenant_id, session_id: session_id)
      record&.email
    end

    def self.mark_verified!(session:, tenant_id:, email:, session_id: nil,
                            ttl: EmailVerificationSession::DEFAULT_TTL)
      normalized = EmailVerificationSession.normalize(email)
      EmailVerificationSession.mark_verified!(session, tenant_id, normalized, ttl: ttl)

      if session_id.present?
        ShopEmailVerification.upsert_verified!(
          tenant_id: tenant_id,
          session_id: session_id,
          email: normalized,
          expires_at: ttl.from_now
        )
      end

      normalized
    end

    def self.clear!(session:, tenant_id:, session_id: nil)
      EmailVerificationSession.clear!(session, tenant_id)
      return if session_id.blank?

      ShopEmailVerification.where(tenant_id: tenant_id, session_id: session_id.to_s).delete_all
    end
  end
end
