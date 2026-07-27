# frozen_string_literal: true

module Shop
  # После подтверждения email: привязка к сессии; при конфликте с phone-сессией — soft-merge.
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

      customer =
        if email_customer && session_customer && email_customer.id != session_customer.id
          CustomerProfileMerger.merge!(survivor: session_customer, donor: email_customer)
        else
          email_customer || session_customer || MobileCustomer.new
        end

      customer.email = @email
      customer.email_verified = true
      customer.first_name = "Гость" if customer.first_name.blank?
      customer.is_active = true
      customer.save!

      CustomerSession.set_customer_id!(@session, @tenant_id, customer.id)
      customer.id
    rescue CustomerProfileMerger::Error => e
      Rails.logger.warn("[Shop::EmailVerifiedCustomerLinker] merge failed: #{e.message}")
      nil
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("[Shop::EmailVerifiedCustomerLinker] link failed: #{e.message}")
      nil
    end
  end
end
