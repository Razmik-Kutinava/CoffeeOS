# frozen_string_literal: true

module Shop
  # После подтверждения email на витрине привязываем MobileCustomer к сессии точки,
  # чтобы frequent_products и профиль работали до следующего заказа.
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

      customer = MobileCustomer.find_or_initialize_by(email: @email)
      customer.first_name = "Гость" if customer.first_name.blank?
      customer.is_active = true
      customer.save!

      CustomerSession.set_customer_id!(@session, @tenant_id, customer.id)
      customer.id
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("[Shop::EmailVerifiedCustomerLinker] link failed: #{e.message}")
      nil
    end
  end
end
