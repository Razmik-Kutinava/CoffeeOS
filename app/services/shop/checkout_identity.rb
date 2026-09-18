# frozen_string_literal: true

module Shop
  # TASK_93-B R1–R5: единая проверка identity для Pay.
  # Phone-first: session customer с phone_verified достаточна; иначе verified email.
  class CheckoutIdentity
    class Error < StandardError; end

    IDENTITY_REQUIRED = "Подтвердите телефон или email"
    EMAIL_OTP_REQUIRED = "Подтвердите email кодом из письма"

    def self.find_or_create_for_order!(session:, tenant:, request:, params:)
      new(session: session, tenant: tenant, request: request, params: params).find_or_create_for_order!
    end

    def self.find_existing!(session:, tenant:, request:, params:)
      new(session: session, tenant: tenant, request: request, params: params).find_existing!
    end

    def initialize(session:, tenant:, request:, params:)
      @session = session
      @tenant = tenant
      @request = request
      @params = params
    end

    def find_or_create_for_order!
      session_customer = load_session_customer

      if phone_ready?(session_customer)
        apply_optional_verified_email!(session_customer)
        apply_name!(session_customer)
        session_customer.is_active = true
        session_customer.save!
        return session_customer
      end

      email = resolve_verified_email!(session_customer)
      customer =
        if session_customer && (session_customer.email.blank? || session_customer.email == email)
          session_customer
        else
          MobileCustomer.find_or_initialize_by(email: email)
        end

      customer.email = email
      customer.email_verified = true
      if session_customer&.phone_verified && session_customer.phone.present?
        customer.phone = session_customer.phone if customer.phone.blank?
        customer.phone_verified = true if customer.phone == session_customer.phone
      end
      apply_name!(customer)
      customer.is_active = true
      customer.save!
      customer
    rescue ActiveRecord::RecordInvalid => e
      raise Error, e.record.errors.full_messages.join(", ")
    end

    def find_existing!
      session_customer = load_session_customer
      return session_customer if phone_ready?(session_customer)

      # R4: same email rules as find_or_create_for_order! (session email_verified OR live OTP)
      email = resolve_verified_email!(session_customer)
      if session_customer && (session_customer.email.blank? || session_customer.email == email)
        return session_customer
      end

      MobileCustomer.find_by!(email: email)
    rescue ActiveRecord::RecordNotFound
      raise Error, "Гость не найден"
    end

    private

    def load_session_customer
      cid = CustomerSession.customer_id(@session, @tenant.id)
      return nil if cid.blank?

      MobileCustomer.find_by(id: cid, is_active: true)
    end

    def phone_ready?(customer)
      customer&.phone_verified
    end

    def resolve_verified_email!(session_customer)
      email = EmailVerificationSession.normalize(@params[:email])
      if email.blank? && session_customer&.email_verified && session_customer.email.present?
        email = session_customer.email
      end
      raise Error, IDENTITY_REQUIRED if email.blank?

      verified_ok =
        if session_customer&.email_verified && session_customer.email == email
          true
        else
          verified = EmailVerification.verified_email(
            session: @session,
            tenant_id: @tenant.id,
            session_id: browser_session_id,
            email: email
          )
          verified == email
        end
      raise Error, EMAIL_OTP_REQUIRED unless verified_ok

      email
    end

    def apply_optional_verified_email!(customer)
      email = EmailVerificationSession.normalize(@params[:email])
      return if email.blank?

      verified_ok =
        if customer.email_verified && customer.email == email
          true
        else
          EmailVerification.verified_email(
            session: @session,
            tenant_id: @tenant.id,
            session_id: browser_session_id,
            email: email
          ) == email
        end
      return unless verified_ok

      customer.email = email
      customer.email_verified = true
    end

    def apply_name!(customer)
      name_parts = @params[:name].to_s.split(/\s+/)
      if name_parts.first.present?
        customer.first_name = name_parts.first
        customer.last_name = name_parts[1..].join(" ").presence
      elsif customer.first_name.blank?
        customer.first_name = "Гость"
      end
    end

    def browser_session_id
      @request&.session&.id&.to_s
    end
  end
end
