class OrderReceiptMailer < ApplicationMailer
  default from: "noreply@coffee.local"

  def send_receipt(order, email)
    @order = order
    @email = email
    mail(to: email, subject: "Чек заказа #{order.order_number}")
  end
end
