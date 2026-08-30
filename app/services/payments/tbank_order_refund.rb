# frozen_string_literal: true

module Payments
  # Общий T-Bank /v2/Cancel + Refund record (guest cancel, shift close, …).
  class TbankOrderRefund
    class Error < StandardError; end

    def self.call!(payment:, tenant_id:, order_id:, reason:)
      new(payment: payment, tenant_id: tenant_id, order_id: order_id, reason: reason).call!
    end

    def initialize(payment:, tenant_id:, order_id:, reason:)
      @payment = payment
      @tenant_id = tenant_id
      @order_id = order_id
      @reason = reason
    end

    def call!
      response = Payments::TbankAdapter.new.cancel_payment(
        payment_id: @payment.provider_payment_id
      )

      ActiveRecord::Base.transaction do
        @payment.update!(status: :refunded)
        Refund.create!(
          tenant_id: @tenant_id,
          payment_id: @payment.id,
          order_id: @order_id,
          amount: @payment.amount,
          reason: @reason,
          status: :succeeded,
          provider_refund_id: response["PaymentId"].presence || @payment.provider_payment_id
        )
      end

      response
    rescue Payments::TbankAdapter::ApiError, Payments::TbankAdapter::Error => e
      Rails.logger.warn(
        "[Payments::TbankOrderRefund] Cancel failed payment=#{@payment.id} " \
        "order=#{@order_id} #{e.class}: #{e.message}"
      )
      raise Error, e.message
    end
  end
end
