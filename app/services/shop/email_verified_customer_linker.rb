# frozen_string_literal: true

module Shop
  # После подтверждения email: привязка к сессии; конфликт → switch на OTP-профиль (не absorb карт).
  class EmailVerifiedCustomerLinker
    def self.link!(session:, tenant_id:, email:)
      new(session: session, tenant_id: tenant_id, email: email).link!
    end

    def initialize(session:, tenant_id:, email:)
      @session = session
      @tenant_id = tenant_id
      @email = EmailVerificationSession.normalize(email)
    end

    def link!
      return nil if @email.blank?

      session_cid = CustomerSession.customer_id(@session, @tenant_id)
      session_customer = session_cid.present? ? MobileCustomer.find_by(id: session_cid) : nil
      email_customer = MobileCustomer.find_by(email: @email)
      action = "attach"
      payment_methods_moved = 0

      customer =
        if email_customer && session_customer && email_customer.id != session_customer.id
          deactivate_empty_guest!(session_customer)
          action = "switch"
          email_customer
        else
          email_customer || session_customer || MobileCustomer.new
        end

      action = "create" if customer.new_record?

      customer.email = @email
      customer.email_verified = true
      customer.first_name = "Гость" if customer.first_name.blank?
      customer.is_active = true
      customer.save!

      previous_cid = session_cid.to_s
      CustomerSession.set_customer_id!(@session, @tenant_id, customer.id)

      if has_active_payment_methods?(customer) && previous_cid.present? && previous_cid != customer.id.to_s
        Payments::BindingStepUp.lock_payments!(@session, @tenant_id)
      end

      log_link!(
        session_customer_id: session_cid,
        otp_customer_id: customer.id,
        action: action,
        payment_methods_moved: payment_methods_moved
      )

      customer.id
    rescue CustomerProfileMerger::Error => e
      Rails.logger.warn("[Shop::EmailVerifiedCustomerLinker] merge failed: #{e.message}")
      nil
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("[Shop::EmailVerifiedCustomerLinker] link failed: #{e.message}")
      nil
    end

    private

    def has_active_payment_methods?(customer)
      MobilePaymentMethod.where(customer_id: customer.id, is_active: true).exists?
    end

    def deactivate_empty_guest!(customer)
      return if has_active_payment_methods?(customer)
      return if Order.where(customer_id: customer.id).exists?

      customer.update_columns(is_active: false)
    end

    def log_link!(session_customer_id:, otp_customer_id:, action:, payment_methods_moved:)
      Rails.logger.info(
        {
          event: "shop.otp_profile_link",
          session_customer_id: session_customer_id,
          otp_customer_id: otp_customer_id,
          action: action,
          payment_methods_moved: payment_methods_moved
        }.to_json
      )
    end
  end
end
