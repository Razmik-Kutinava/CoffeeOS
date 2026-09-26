# frozen_string_literal: true

require "test_helper"

module Subscriptions
  class PurchaseServiceTest < ActiveSupport::TestCase
    include TestFactories

    setup do
      @tenant = create_tenant!(slug: "sub-#{SecureRandom.hex(3)}")
      Current.tenant_id = @tenant.id
      @customer = create_mobile_customer!(email: "sub-#{SecureRandom.hex(4)}@example.com")
      @payment_method = MobilePaymentMethod.create!(
        customer_id: @customer.id,
        payment_type: "card",
        card_token: "rebill-sub-1",
        card_masked: "*4242",
        is_active: true,
        is_default: true
      )
    end

    teardown { Current.reset }

    def confirmed_adapter
      fake = Object.new
      fake.define_singleton_method(:init_payment) do |**_kw|
        { provider_payment_id: "pid-sub-1", payment_url: "https://pay.example/pid-sub-1" }
      end
      fake.define_singleton_method(:charge) do |payment_id:, rebill_id:|
        raise "unexpected rebill #{rebill_id}" unless rebill_id == "rebill-sub-1"
        raise "unexpected pid #{payment_id}" unless payment_id == "pid-sub-1"

        {
          "Success" => true,
          "Status" => "CONFIRMED",
          "PaymentId" => "pid-sub-1",
          "ErrorCode" => "0"
        }
      end
      fake
    end

    test "[TDD] successful purchase creates active subscription with period snapshot" do
      plan = SubscriptionPlan.create!(
        code: "pilot_weekly",
        price: 499,
        currency: "RUB",
        period_days: 7,
        drink_limit: 5,
        discount_price_per_drink: 119,
        over_limit_discount_percent: 20,
        active: true
      )

      result = Subscriptions::PurchaseService.call(
        customer: @customer,
        plan: plan,
        purchase_point: @tenant,
        payment_method: @payment_method,
        return_base_url: "https://example.com",
        notification_url: "https://example.com/callbacks/tbank",
        auto_renew: true,
        utm_campaign: "spring",
        utm_content: "hero",
        offer_channel: "banner",
        adapter: confirmed_adapter
      )

      sub = Subscription.find_by!(customer_id: @customer.id)
      assert_equal "active", sub.status
      assert_equal plan.id, sub.plan_id
      assert_equal @tenant.id, sub.purchase_point_id
      assert_equal @payment_method.id, sub.payment_method_id
      assert_equal 0, sub.drinks_used_this_period
      assert_equal BigDecimal("499"), sub.price_at_period_start
      assert_equal 5, sub.drink_limit_at_period_start
      assert_equal 20, sub.discount_percent_at_period_start
      assert_equal "spring", sub.utm_campaign
      assert_equal "hero", sub.utm_content
      assert_equal "banner", sub.offer_channel
      assert sub.auto_renew
      assert sub.current_period_start.present?
      assert_operator sub.current_period_end, :>, sub.current_period_start
      assert_equal (sub.current_period_start + 7.days).to_i, sub.current_period_end.to_i

      assert result[:provider_payment_id] == "pid-sub-1"
      payment = Payment.find_by!(order_id: result[:order_id])
      assert_equal "tbank", payment.provider
      assert_equal "pid-sub-1", payment.provider_payment_id
      assert_predicate payment, :succeeded?

      order = Order.find(result[:order_id])
      assert_equal "closed", order.status, "technical subscription order must not stay on barista board"
    end

    test "purchase without saved PM returns payment_url and does not invent payment_method_id" do
      plan = SubscriptionPlan.create!(
        code: "pilot_redirect",
        price: 99,
        currency: "RUB",
        period_days: 7,
        drink_limit: 5,
        discount_price_per_drink: 119,
        over_limit_discount_percent: 20,
        active: true
      )
      fake = Object.new
      fake.define_singleton_method(:init_payment) do |**_kw|
        { provider_payment_id: "pid-redir-1", payment_url: "https://pay.example/pid-redir-1" }
      end
      fake.define_singleton_method(:charge) { |**_| raise "charge must not run without rebill" }

      result = Subscriptions::PurchaseService.call(
        customer: @customer,
        plan: plan,
        purchase_point: @tenant,
        payment_method: nil,
        payment_method_type: "sbp",
        return_base_url: "https://example.com",
        notification_url: "https://example.com/callbacks/tbank",
        offer_channel: "lk",
        adapter: fake
      )

      assert result[:pending_payment]
      assert_equal "https://pay.example/pid-redir-1", result[:payment_url]
      assert_nil result[:subscription_id]
      payment = Payment.find_by!(order_id: result[:order_id])
      assert_equal "sbp", payment.method
      assert_nil payment.provider_data["subscription_payment_method_id"]
      assert ActiveModel::Type::Boolean.new.cast(payment.provider_data["save_sbp_account"])
      refute Subscription.exists?(customer_id: @customer.id)
    end
  end
end
