# frozen_string_literal: true

module Subscriptions
  # #78 slice 4: дожать оплату подписки через GetState (3DS / отложенный webhook).
  class ConfirmPaymentService
    class Error < StandardError; end

    def self.call(customer:, adapter: nil)
      new(customer: customer, adapter: adapter).call
    end

    def initialize(customer:, adapter: nil)
      @customer = customer
      @adapter = adapter
    end

    def call
      raise Error, "customer missing" if @customer.blank?

      payment = pending_subscription_payment
      if payment
        Payments::TbankPaymentSync.sync_order!(order: payment.order, adapter: @adapter)
        payment.reload
        if payment.succeeded?
          Subscriptions::PaymentFulfillment.call(payment: payment)
        end
      end

      sub = current_open_subscription
      return sub if sub&.active? || sub&.past_due?

      raise Error, "subscription payment not confirmed" if payment && !payment.succeeded?
      raise Error, "no pending subscription payment"
    end

    private

    def current_open_subscription
      Subscription.for_customer(@customer.id)
        .where(status: [ :active, :past_due, :pending ])
        .order(updated_at: :desc)
        .first
    end

    def pending_subscription_payment
      Payment.joins(:order)
        .where(orders: { customer_id: @customer.id, source: :mobile })
        .where(status: :pending, provider: "tbank")
        .where("payments.provider_data ->> 'subscription_intent' = 'true'")
        .order(created_at: :desc)
        .first
    end
  end
end
