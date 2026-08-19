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
      OrderReceiptMailer.send_receipt(order, order_email.email).deliver_later
      order_email.update(status: :sent)
    rescue => e
      Rails.logger.error("[SendOrderReceiptEmailJob] Failed to send receipt for order_email #{order_email_id}: #{e.message}")
      order_email.update(status: :failed)
    end
  end
end
