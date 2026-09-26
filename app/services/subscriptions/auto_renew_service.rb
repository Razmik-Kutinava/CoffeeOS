# frozen_string_literal: true

module Subscriptions
  # Патч 1 Subtask 14: отключение auto_renew только при usage в текущем оплаченном периоде.
  class AutoRenewService
    class Error < StandardError; end

    def self.call(subscription:, auto_renew:)
      new(subscription: subscription, auto_renew: auto_renew).call
    end

    def initialize(subscription:, auto_renew:)
      @subscription = subscription
      @auto_renew = ActiveModel::Type::Boolean.new.cast(auto_renew)
    end

    def call
      raise Error, "subscription missing" if @subscription.blank?

      if @auto_renew == false && !@subscription.used_in_current_period?
        raise Error, "auto_renew off requires usage in current paid period; cancel instead"
      end

      @subscription.update!(auto_renew: @auto_renew)
      @subscription
    end
  end
end
