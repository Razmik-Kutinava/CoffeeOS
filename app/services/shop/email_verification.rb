# frozen_string_literal: true

module Shop
  # Подтверждение email на витрине: Rails session + Postgres (per tenant + browser session).
  # DB даёт общий источник между web-инстансами без Redis.
  # Fallback по email: повторный визит после смены cookie session_id (мобильные браузеры).
  class EmailVerification
    def self.verified_email(session:, tenant_id:, session_id: nil, email: nil)
      from_session = EmailVerificationSession.verified_email(session, tenant_id)
      return from_session if from_session.present?

      record = lookup_active_record(tenant_id: tenant_id, session_id: session_id, email: email)
      return nil unless record

      rehydrate!(session: session, tenant_id: tenant_id, session_id: session_id, record: record)
      record.email
    end

    def self.mark_verified!(session:, tenant_id:, email:, session_id: nil,
                            ttl: EmailVerificationSession::DEFAULT_TTL)
      normalized = EmailVerificationSession.normalize(email)
      expires_at = ttl.from_now
      EmailVerificationSession.mark_verified!(session, tenant_id, normalized, ttl: ttl)

      if session_id.present?
        ShopEmailVerification.upsert_verified!(
          tenant_id: tenant_id,
          session_id: session_id,
          email: normalized,
          expires_at: expires_at
        )
        ShopEmailVerification.active
          .where(tenant_id: tenant_id, email: normalized)
          .where.not(session_id: session_id.to_s)
          .delete_all
      end

      normalized
    end

    def self.clear!(session:, tenant_id:, session_id: nil)
      EmailVerificationSession.clear!(session, tenant_id)
      return if session_id.blank?

      ShopEmailVerification.where(tenant_id: tenant_id, session_id: session_id.to_s).delete_all
    end

    def self.lookup_active_record(tenant_id:, session_id: nil, email: nil)
      if session_id.present?
        record = ShopEmailVerification.active_for(tenant_id: tenant_id, session_id: session_id)
        return record if record
      end

      normalized = EmailVerificationSession.normalize(email) if email.present?
      return nil if normalized.blank?

      ShopEmailVerification.active_for_email(tenant_id: tenant_id, email: normalized)
    end
    private_class_method :lookup_active_record

    def self.rehydrate!(session:, tenant_id:, session_id:, record:)
      remaining = record.expires_at - Time.current
      return if remaining <= 0

      EmailVerificationSession.mark_verified!(
        session,
        tenant_id,
        record.email,
        ttl: remaining.seconds
      )

      sid = session_id.to_s
      return if sid.blank? || sid == record.session_id.to_s

      ShopEmailVerification.upsert_verified!(
        tenant_id: tenant_id,
        session_id: sid,
        email: record.email,
        expires_at: record.expires_at
      )
      ShopEmailVerification.active
        .where(tenant_id: tenant_id, email: record.email)
        .where.not(session_id: sid)
        .delete_all
    end
    private_class_method :rehydrate!
  end
end
