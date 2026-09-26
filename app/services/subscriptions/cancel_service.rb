# frozen_string_literal: true

module Subscriptions
  # #78 / Патч 1: отмена. Usage = events в текущем оплаченном периоде (не drinks_used_this_period).
  class CancelService
    class Error < StandardError; end

    def self.call(subscription:)
      new(subscription: subscription).call
    end

    def initialize(subscription:)
      @subscription = subscription
    end

    def call
      raise Error, "subscription missing" if @subscription.blank?
      return @subscription if @subscription.canceled?

      unless @subscription.active? || @subscription.past_due?
        raise Error, "subscription cannot be canceled"
      end

      unused = !@subscription.used_in_current_period?

      @subscription.update!(status: :canceled, auto_renew: false)

      if unused
        TelegramAlertJob.perform_later(
          "Subscription cancel without usage — manual refund required",
          {
            subscription_id: @subscription.id,
            customer_id: @subscription.customer_id,
            plan_id: @subscription.plan_id,
            price_at_period_start: @subscription.price_at_period_start.to_s
          }
        )
      end

      @subscription
    end
  end
end
