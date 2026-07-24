# frozen_string_literal: true

module Shop
  # Silent Refresh: валидный refresh_token → cookie customer_id + ротация токена.
  class SessionRefresh
    class Unauthorized < StandardError; end

    TTL = 90.days

    def self.call!(session:, tenant_id:, refresh_token:)
      new(session: session, tenant_id: tenant_id, refresh_token: refresh_token).call!
    end

    def initialize(session:, tenant_id:, refresh_token:)
      @session = session
      @tenant_id = tenant_id
      @refresh_token = refresh_token.to_s.strip
    end

    def call!
      raise Unauthorized if @refresh_token.blank?

      ms = MobileSession.find_by(refresh_token: @refresh_token)
      raise Unauthorized unless ms&.active?

      customer = ms.customer
      raise Unauthorized unless customer

      new_token = nil
      ActiveRecord::Base.transaction do
        ms.deactivate!
        new_token = MobileSessionIssuer.call!(customer_id: customer.id)
        CustomerSession.set_customer_id!(@session, @tenant_id, customer.id)
        extend_email_verification!(customer)
      end

      {
        refresh_token: new_token,
        profile: profile_for(customer)
      }
    end

    private

    def extend_email_verification!(customer)
      email = customer.email
      return if email.blank?

      EmailVerification.mark_verified!(
        session: @session,
        tenant_id: @tenant_id,
        email: email,
        ttl: TTL
      )
    end

    def profile_for(customer)
      {
        id: customer.id,
        name: customer.full_name.presence || customer.first_name,
        email: customer.email,
        phone: customer.phone
      }
    end
  end
end
