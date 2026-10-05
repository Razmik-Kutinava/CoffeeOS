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

    # #71 Патч_2: post-pay email → MobileCustomer.receipt_email (prefill следующего заказа).
    # MobileCustomer.email / email_verified не трогаем: это identity (OTP) и Receipt.Email
    # в TbankReceiptBuilder.for_order!.
    def persist_customer_contact!(email_value)
      customer = @order.customer
      return unless customer

      if email_value.blank?
        customer.update!(receipt_email: nil) if customer.receipt_email.present?
        return
      end

      return if customer.receipt_email == email_value

      customer.receipt_email = email_value
      customer.email_collected_at ||= Time.current
      customer.save!
    rescue ActiveRecord::RecordInvalid => e
      raise ValidationError, e.record.errors.full_messages.join(", ")
    end
  end
end
