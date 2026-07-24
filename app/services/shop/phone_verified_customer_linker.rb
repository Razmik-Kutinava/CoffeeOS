# frozen_string_literal: true

module Shop
  # После phone OTP: find/create MobileCustomer по phone, связать с email-сессией если возможно.
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

      if phone_customer && session_customer && phone_customer.id != session_customer.id
        raise Error, "Этот телефон уже привязан к другому аккаунту (конфликт с email)"
      end

      customer = phone_customer || session_customer || MobileCustomer.new
      customer.phone = @phone
      customer.first_name = "Гость" if customer.first_name.blank?
      customer.is_active = true
      customer.save!

      CustomerSession.set_customer_id!(@session, @tenant_id, customer.id)
      customer.id
    rescue PhoneNormalizer::Error => e
      raise Error, e.message
    rescue ActiveRecord::RecordInvalid => e
      raise Error, e.record.errors.full_messages.to_sentence.presence || e.message
    end
  end
end
