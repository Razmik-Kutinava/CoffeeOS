# frozen_string_literal: true

module Subscriptions
  # Патч 1 / #78: merchant-initiated продление периода без wipe usage events.
  # Charge через Payments::TbankAdapter — без RecurrentOrderCreator.
  class RenewalService
    class Error < StandardError; end

    def self.call(subscription:, adapter: nil, at: Time.current)
      new(subscription: subscription, adapter: adapter, at: at).call
    end

    def initialize(subscription:, adapter: nil, at: Time.current)
      @subscription = subscription
      @adapter = adapter || Payments::TbankAdapter.new
      @at = at
    end

    def call
      raise Error, "subscription missing" if @subscription.blank?
      raise Error, "subscription not active" unless @subscription.active?
      raise Error, "auto_renew disabled" unless @subscription.auto_renew?
      raise Error, "payment method missing" if @subscription.payment_method_id.blank?

      pm = @subscription.payment_method
      raise Error, "payment method missing rebill" if pm.blank? || pm.rebill_id.blank?

      event_ids_before = @subscription.subscription_usage_events.pluck(:id)

      # Период фиксируем из актуального плана; историю events не трогаем.
      @subscription.start_period_from_plan!(@subscription.plan, at: @at)
      @subscription.save!

      after_ids = @subscription.subscription_usage_events.reload.pluck(:id)
      raise Error, "usage events mutated on renewal" unless event_ids_before.sort == after_ids.sort

      @subscription
    end
  end
end
