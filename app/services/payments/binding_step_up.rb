# frozen_string_literal: true

module Payments
  # #75 + V3-SEC-OTP-MERGE: step-up OTP на телефон аккаунта; lock списаний после OTP-login.
  class BindingStepUp
    RISK_STATUSES = %w[recycled_risk].freeze
    SESSION_LOCK_KEY = :shop_payments_locked_by_tenant

    def self.otp_phone_for(customer)
      customer&.phone.to_s.presence
    end

    def self.requires_step_up?(customer, session: nil, tenant_id: nil)
      return false if customer.blank?

      status = customer.phone_status.to_s
      return true if RISK_STATUSES.include?(status)
      return true if status == "unverified" && customer.phone.present?
      return true if session && tenant_id && payments_locked?(session, tenant_id)

      false
    end

    # Никогда не брать телефон из client params.
    def self.resolve_otp_destination(customer:, form_phone: nil)
      account = otp_phone_for(customer)
      return account if account.present?

      nil
    end

    def self.lock_payments!(session, tenant_id)
      return if session.blank? || tenant_id.blank?

      tid = tenant_id.to_s
      bucket = session[SESSION_LOCK_KEY]
      bucket = bucket.is_a?(Hash) ? bucket.dup : {}
      bucket[tid] = true
      session[SESSION_LOCK_KEY] = bucket
    end

    def self.unlock_payments!(session, tenant_id)
      return if session.blank? || tenant_id.blank?

      tid = tenant_id.to_s
      bucket = session[SESSION_LOCK_KEY]
      return unless bucket.is_a?(Hash)

      bucket = bucket.dup
      bucket.delete(tid)
      if bucket.empty?
        session.delete(SESSION_LOCK_KEY)
      else
        session[SESSION_LOCK_KEY] = bucket
      end
    end

    def self.payments_locked?(session, tenant_id)
      return false if session.blank? || tenant_id.blank?

      bucket = session[SESSION_LOCK_KEY]
      bucket.is_a?(Hash) && bucket[tenant_id.to_s] == true
    end
  end
end
