# frozen_string_literal: true

module Shop
  # Гость витрины: customer_id из Rails-сессии или из подтверждённого email (БД).
  # Нужен после F5 / новой cookie: OTP не должен требоваться снова, пока verification жива.
  class GuestCustomerResolver
    def self.call(session:, tenant_id:, email: nil)
      cid = CustomerSession.customer_id(session, tenant_id)
      return cid if cid.present?

      normalized = EmailVerificationSession.normalize(email)
      return nil if normalized.blank?

      verified = EmailVerification.verified_email(
        session: session,
        tenant_id: tenant_id,
        email: normalized
      )
      return nil unless verified == normalized

      linked = EmailVerifiedCustomerLinker.link!(
        session: session,
        tenant_id: tenant_id,
        email: normalized
      )
      linked&.to_s
    end
  end
end
