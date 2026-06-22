# frozen_string_literal: true

# Редирект с SuccessURL/FailURL Т-Банка в hash-SPA витрины.
class PaymentReturnsController < ApplicationController
  def success
    redirect_to shop_payment_hash("success", params[:order_id], bound: card_binding?(params[:order_id]))
  end

  def fail
    record_shop_payment_fail_return!(params[:order_id])
    redirect_to shop_payment_hash("fail", params[:order_id])
  end

  private

  def record_shop_payment_fail_return!(order_id)
    order = Order.find_by(id: order_id)
    return unless order&.pending_payment? && order.mobile?

    payment = order.payments.find_by(status: :pending) || order.payments.order(created_at: :desc).first
    Shop::PaymentFailureJournal.record!(
      order: order,
      payment: payment,
      reason: :bank_fail_return,
      source: :customer,
      details: { trigger: "tbank_fail_url" }
    )
  rescue StandardError => e
    Rails.logger.error("[PaymentReturns] fail journal error: #{e.class} #{e.message}")
  end

  def shop_payment_hash(status, order_id, bound: false)
    order = Order.find_by(id: order_id)
    base = ENV.fetch("TBANK_RETURN_URL", request.base_url).to_s.chomp("/")
    tenant_q = order ? "?tenant_id=#{order.tenant_id}" : ""
    bound_q = bound ? "&bound=1" : ""
    "#{base}/shop#{tenant_q}#/payment-result?status=#{status}&order_id=#{order_id}#{bound_q}"
  end

  def card_binding?(order_id)
    order = Order.find_by(id: order_id)
    return false unless order&.mobile?

    order.payments.where(provider: "tbank").exists? || order.customer_id.present?
  end
end
