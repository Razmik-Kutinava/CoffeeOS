# frozen_string_literal: true

module Shop
  # После phone OTP: find/create MobileCustomer по phone; конфликт → switch на OTP-профиль (не absorb карт).
  class PhoneVerifiedCustomerLinker
    class Error < StandardError; end

    def self.link!(session:, tenant_id:, phone:)
      new(session: session, tenant_id: tenant_id, phone: phone).link!
    end

    def initialize(session:, tenant_id:, phone:)
      @session = session
      @tenant_id = tenant_id
      @phone = PhoneNormalizer.normalize!(phone)
    end

    def link!
      session_cid = CustomerSession.customer_id(@session, @tenant_id)
      session_customer = session_cid.present? ? MobileCustomer.find_by(id: session_cid) : nil
      phone_customer = MobileCustomer.find_by(phone: @phone)
      action = "attach"
      payment_methods_moved = 0

      customer =
        if phone_customer && session_customer && phone_customer.id != session_customer.id
          deactivate_empty_guest!(session_customer)
          action = "switch"
          phone_customer
        else
          phone_customer || session_customer || MobileCustomer.new
        end

      action = "create" if customer.new_record?

      customer.phone = @phone
      customer.phone_verified = true
      customer.first_name = "Гость" if customer.first_name.blank?
      customer.is_active = true
      customer.save!

      previous_cid = session_cid.to_s
      CustomerSession.set_customer_id!(@session, @tenant_id, customer.id)

      if has_active_payment_methods?(customer) && previous_cid != customer.id.to_s
        Payments::BindingStepUp.lock_payments!(@session, @tenant_id)
      end

      log_link!(
        session_customer_id: session_cid,
        otp_customer_id: customer.id,
        action: action,
        payment_methods_moved: payment_methods_moved
      )

      customer.id
    rescue PhoneNormalizer::Error => e
      raise Error, e.message
    rescue CustomerProfileMerger::Error => e
      raise Error, e.message
    rescue ActiveRecord::RecordInvalid => e
      raise Error, e.record.errors.full_messages.to_sentence.presence || e.message
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
