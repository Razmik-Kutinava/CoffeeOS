class SendOrderReceiptEmailJob < ApplicationJob
  queue_as :default

  def perform(order_email_id)
    order_email = OrderEmail.find_by(id: order_email_id)
    return if order_email.blank?

    order = order_email.order
    return if order.blank?

    if order_email.email.blank?
      order_email.update(status: :sent)
      return
    end

    begin
      Shop::OrderReceiptEmailDelivery.deliver!(order: order, email: order_email.email)
      order_email.update(status: :sent)
    rescue Shop::BrevoClient::Error => e
      Rails.logger.error("[SendOrderReceiptEmailJob] Brevo failed for order_email #{order_email_id}: #{e.message}")
      order_email.update(status: :failed)
    rescue => e
      Rails.logger.error("[SendOrderReceiptEmailJob] Failed to send receipt for order_email #{order_email_id}: #{e.message}")
      order_email.update(status: :failed)
    end
  end
end
