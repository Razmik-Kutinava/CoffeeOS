# frozen_string_literal: true

# Редирект с SuccessURL/FailURL Т-Банка в hash-SPA витрины.
class PaymentReturnsController < ApplicationController
  def success
    redirect_to shop_payment_hash("success", params[:order_id])
  end

  def fail
    redirect_to shop_payment_hash("fail", params[:order_id])
  end

  private

  def shop_payment_hash(status, order_id)
    order = Order.find_by(id: order_id)
    base = ENV.fetch("TBANK_RETURN_URL", request.base_url).to_s.chomp("/")
    tenant_q = order ? "?tenant_id=#{order.tenant_id}" : ""
    "#{base}/shop#{tenant_q}#/payment-result?status=#{status}&order_id=#{order_id}"
  end
end
