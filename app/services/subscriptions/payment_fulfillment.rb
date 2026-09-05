# frozen_string_literal: true

module Subscriptions
  # Идемпотентное завершение оплаты подписки (sync PurchaseService или T-Bank webhook).
  # Не вызывает PaymentStatusUpdater → accepted (табло баристы).
  class PaymentFulfillment
    class Error < StandardError; end

    def self.call(payment:)
      new(payment: payment).call
    end

    def initialize(payment:)
      @payment = payment
    end

    def call
      data = @payment.provider_data
      return nil unless data.is_a?(Hash)
      return nil unless ActiveModel::Type::Boolean.new.cast(data["subscription_intent"])

      existing = Subscription.find_by(payment_id: @payment.id)
      return existing if existing

      plan_id = data["subscription_plan_id"].presence
      raise Error, "subscription_plan_id missing" if plan_id.blank?

      plan = SubscriptionPlan.find(plan_id)
      customer_id = @payment.order.customer_id
      raise Error, "order without customer" if customer_id.blank?

      pm_id = data["subscription_payment_method_id"].presence
      auto_renew = ActiveModel::Type::Boolean.new.cast(data.fetch("auto_renew", true))

      subscription = Subscription.new(
        customer_id: customer_id,
        plan_id: plan.id,
        purchase_point_id: @payment.order.tenant_id,
        payment_method_id: pm_id,
        payment_id: @payment.id,
        auto_renew: auto_renew,
        status: :active
      )
      subscription.start_period_from_plan!(plan)
      subscription.save!
      subscription
    end
  end
end
