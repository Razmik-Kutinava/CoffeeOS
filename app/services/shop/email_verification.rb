# frozen_string_literal: true

module Shop
  # Подтверждение email на витрине: Postgres (tenant + email) + Rails session как кэш.
  # Источник истины — tenant + email; не зависит от browser session_id.
  class EmailVerification
    def self.verified_email(session:, tenant_id:, session_id: nil, email: nil)
      normalized = EmailVerificationSession.normalize(email) if email.present?
      if normalized.present?
        record = ShopEmailVerification.active_for(tenant_id: tenant_id, email: normalized)
        if record
          hydrate_session!(session: session, tenant_id: tenant_id, record: record)
          return record.email
        end
      end

      EmailVerificationSession.verified_email(session, tenant_id)
    end

    def self.mark_verified!(session:, tenant_id:, email:, session_id: nil,
                            ttl: EmailVerificationSession::DEFAULT_TTL)
      normalized = EmailVerificationSession.normalize(email)
      expires_at = ttl.from_now
      EmailVerificationSession.mark_verified!(session, tenant_id, normalized, ttl: ttl)
      ShopEmailVerification.upsert_verified!(
        tenant_id: tenant_id,
        email: normalized,
        expires_at: expires_at
      )
      normalized
    end

    def self.clear!(session:, tenant_id:, email: nil, session_id: nil)
      EmailVerificationSession.clear!(session, tenant_id)

      normalized = EmailVerificationSession.normalize(email) if email.present?
      if normalized.present?
        ShopEmailVerification.where(tenant_id: tenant_id, email: normalized).delete_all
      end
    end

    def self.hydrate_session!(session:, tenant_id:, record:)
      remaining = record.expires_at - Time.current
      return if remaining <= 0

      EmailVerificationSession.mark_verified!(
        session,
        tenant_id,
        record.email,
        ttl: remaining.seconds
      )
    end
    private_class_method :hydrate_session!
  end
end
