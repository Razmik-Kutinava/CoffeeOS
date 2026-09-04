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
        success_response(order_email, queued_receipt: true)
      else
        if order_email.save
          mark_customer_email_collected!
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

    # #77: first successful order email → customer.email_collected_at (idempotent).
    def mark_customer_email_collected!
      customer = @order.customer
      return unless customer

      customer.mark_email_collected!
    end
  end
end
