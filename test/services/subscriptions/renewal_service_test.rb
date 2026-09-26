# frozen_string_literal: true

require "test_helper"

module Subscriptions
  class RenewalServiceTest < ActiveSupport::TestCase
    include TestFactories

    setup do
      @tenant = create_tenant!
      Current.tenant_id = @tenant.id
      @customer = create_mobile_customer!(email: "ren-#{SecureRandom.hex(3)}@ex.com")
      @plan = SubscriptionPlan.create!(
        code: "ren_#{SecureRandom.hex(2)}",
        price: 99,
        currency: "RUB",
        period_days: 7,
        drink_limit: 5,
        discount_price_per_drink: 119,
        over_limit_discount_percent: 20,
        active: true
      )
      @pm = MobilePaymentMethod.create!(
        customer_id: @customer.id,
        payment_type: "card",
        card_token: "rebill-ren-1",
        card_masked: "*4242",
        is_active: true,
        is_default: true
      )
      @sub = Subscription.create!(
        customer_id: @customer.id,
        plan_id: @plan.id,
        purchase_point_id: @tenant.id,
        payment_method_id: @pm.id,
        status: :active,
        auto_renew: true,
        drinks_used_this_period: 3,
        drink_limit_at_period_start: 5,
        price_at_period_start: 99,
        discount_percent_at_period_start: 20,
        current_period_start: 7.days.ago,
        current_period_end: Time.current,
        utm_campaign: "camp-a",
        utm_content: "banner-1",
        offer_channel: "banner"
      )
      order = Order.create!(
        tenant_id: @tenant.id,
        customer_id: @customer.id,
        customer_name: "U",
        order_number: "ren-#{SecureRandom.hex(2)}",
        source: :mobile,
        status: :closed,
        total_amount: 119,
        discount_amount: 0,
        final_amount: 119
      )
      @event = SubscriptionUsageEvent.create!(
        subscription_id: @sub.id,
        order_id: order.id,
        point_id: @tenant.id,
        applied_price: 119,
        savings_amount: 81,
        pricing_kind: "in_limit"
      )
    end

    teardown { Current.reset }

    test "renewal starts new period and keeps usage events and attribution" do
      at = Time.zone.parse("2026-09-26 15:00:00")
      result = RenewalService.call(subscription: @sub, at: at)

      assert_equal "active", result.status
      assert_equal at.to_i, result.current_period_start.to_i
      assert_equal (at + 7.days).to_i, result.current_period_end.to_i
      assert_equal [ @event.id ], result.subscription_usage_events.pluck(:id)
      assert_equal "camp-a", result.utm_campaign
      assert_equal "banner", result.offer_channel
    end
  end
end
