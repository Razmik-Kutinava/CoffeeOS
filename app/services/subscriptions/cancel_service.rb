# frozen_string_literal: true

module Subscriptions
  # #78 slice 3: отмена текущей подписки (active/past_due).
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

      @subscription.update!(status: :canceled, auto_renew: false)
      @subscription
    end
  end
end
