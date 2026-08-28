# frozen_string_literal: true

module Shop
  # #71: чек после оплаты — через Brevo (как OTP), не ActionMailer → localhost:25.
  class OrderReceiptEmailDelivery
    def self.deliver!(order:, email:)
      mail = OrderReceiptMailer.send_receipt(order, email)
      html = mail.html_part&.body&.decoded || mail.body.decoded
      text = mail.text_part&.body&.decoded

      BrevoClient.deliver_html!(
        to: email,
        subject: mail.subject,
        html_content: html,
        text_content: text
      )
    end
  end
end
