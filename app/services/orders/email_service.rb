module Orders
  class EmailService
    class ValidationError < StandardError; end

    def initialize(order)
      @order = order
    end

    def save_email(email:, marketing_consent: false)
      email_value = email&.strip&.downcase || ""

      if email_value.present? && !valid_email?(email_value)
        raise ValidationError, "Invalid email format"
      end

      if email_value.blank?
        persist_customer_contact!("")
        return success_response(
          @order.order_emails.build(email: "", marketing_consent: false),
          queued_receipt: true
        )
      end

      order_email = nil
      ActiveRecord::Base.transaction do
        # Profile first — fail without OrderEmail/jobs if uniqueness/conflict.
        persist_customer_contact!(email_value)
        order_email = find_or_create_order_email(email_value, marketing_consent)
        unless order_email.save
          raise ValidationError, order_email.errors.full_messages.join(", ")
        end
      end

      success_response(order_email, queued_receipt: true)
    end

    private

    def valid_email?(email)
      # URI::MailTo — без polynomial backtracking (CodeQL rb/polynomial-redos).
      URI::MailTo::EMAIL_REGEXP.match?(email)
    end

    def find_or_create_order_email(email, marketing_consent)
      @order.order_emails.find_or_initialize_by(email: email) do |oe|
        oe.marketing_consent = marketing_consent
      end
    end

    def success_response(order_email, queued_receipt: false)
      {
        success: true,
        email: order_email.email,
        queued_receipt: queued_receipt,
        marketing_consent: order_email.marketing_consent
      }
    end

    # #71 Патч_1: post-pay email → MobileCustomer for server prefill.
    # Never marks email_verified (OTP path only). Releases unverified squat on other rows.
    def persist_customer_contact!(email_value)
      customer = @order.customer
      return unless customer

      if email_value.blank?
        return if customer.email.blank?

        customer.update!(email: nil, email_verified: false)
        return
      end

      return if customer.email == email_value

      release_unverified_email_claim!(email_value, except_id: customer.id)

      other = MobileCustomer.where(email: email_value).where.not(id: customer.id).first
      if other&.email_verified?
        raise ValidationError, "Email already in use"
      end

      customer.email = email_value
      customer.email_verified = false
      customer.email_collected_at ||= Time.current
      customer.save!
    rescue ActiveRecord::RecordInvalid => e
      raise ValidationError, e.record.errors.full_messages.join(", ")
    end

    def release_unverified_email_claim!(email_value, except_id:)
      MobileCustomer
        .where(email: email_value, email_verified: false)
        .where.not(id: except_id)
        .find_each { |row| row.update!(email: nil) }
    end
  end
end
