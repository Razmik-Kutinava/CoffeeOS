# frozen_string_literal: true

module Payments
  # #75: step-up OTP только на телефон аккаунта (не из формы).
  class BindingStepUp
    RISK_STATUSES = %w[recycled_risk].freeze

    def self.otp_phone_for(customer)
      customer&.phone.to_s.presence
    end

    def self.requires_step_up?(customer)
      return false if customer.blank?

      status = customer.phone_status.to_s
      return true if RISK_STATUSES.include?(status)
      return true if status == "unverified" && customer.phone.present?

      false
    end

    # Никогда не брать телефон из client params.
    def self.resolve_otp_destination(customer:, form_phone: nil)
      account = otp_phone_for(customer)
      return account if account.present?

      nil
    end
  end
end
