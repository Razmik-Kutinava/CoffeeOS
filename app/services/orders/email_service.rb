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

      order_email = if email_value.present?
        find_or_create_order_email(email_value, marketing_consent)
      else
        @order.order_emails.build(email: "", marketing_consent: false)
      end

      if email_value.blank?
        persist_customer_contact!("")
        success_response(order_email, queued_receipt: true)
      else
        if order_email.save
          persist_customer_contact!(email_value)
          success_response(order_email, queued_receipt: true)
        else
          raise ValidationError, order_email.errors.full_messages.join(", ")
        end
      end
    end

    private

    def valid_email?(email)
      email.match?(/\A[^\s@]+@[^\s@]+\.[^\s@]+\z/)
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

    # #71 Патч_1: post-pay email → MobileCustomer profile (verified phone), not only OrderEmail.
    def persist_customer_contact!(email_value)
      customer = @order.customer
      return unless customer

      if email_value.blank?
        return if customer.email.blank?

        customer.update!(email: nil)
        return
      end

      return if customer.email == email_value

      customer.email = email_value
      customer.email_collected_at ||= Time.current
      customer.save!
    rescue ActiveRecord::RecordInvalid => e
      raise ValidationError, e.record.errors.full_messages.join(", ")
    end
  end
end
