# frozen_string_literal: true

require "test_helper"

module Subscriptions
  class AutoRenewServiceTest < ActiveSupport::TestCase
    include TestFactories

    setup do
      @tenant = create_tenant!
      Current.tenant_id = @tenant.id
      @customer = create_mobile_customer!(email: "ar-#{SecureRandom.hex(3)}@ex.com")
      @plan = SubscriptionPlan.create!(
        code: "ar_#{SecureRandom.hex(2)}",
        price: 99,
        currency: "RUB",
        period_days: 7,
        drink_limit: 5,
        discount_price_per_drink: 119,
        over_limit_discount_percent: 20,
        active: true
      )
      @period_start = Time.zone.parse("2026-09-20 10:00:00")
      @sub = Subscription.create!(
        customer_id: @customer.id,
        plan_id: @plan.id,
        purchase_point_id: @tenant.id,
        status: :active,
        auto_renew: true,
        drinks_used_this_period: 5,
        drink_limit_at_period_start: 5,
        price_at_period_start: 99,
        discount_percent_at_period_start: 20,
        current_period_start: @period_start,
        current_period_end: @period_start + 7.days
      )
    end

    teardown { Current.reset }

    def seed_period_event!
      order = Order.create!(
        tenant_id: @tenant.id,
        customer_id: @customer.id,
        customer_name: "U",
        order_number: "ar-#{SecureRandom.hex(2)}",
        source: :mobile,
        status: :closed,
        total_amount: 119,
        discount_amount: 0,
        final_amount: 119
      )
      SubscriptionUsageEvent.create!(
        subscription_id: @sub.id,
        order_id: order.id,
        point_id: @tenant.id,
        applied_price: 119,
        savings_amount: 81,
        pricing_kind: "in_limit",
        created_at: @period_start + 1.day,
        updated_at: @period_start + 1.day
      )
    end

    test "disables auto_renew when usage exists in current paid period" do
      seed_period_event!
      result = AutoRenewService.call(subscription: @sub, auto_renew: false)
      assert_equal false, result.auto_renew
      assert_equal "active", result.status
      assert_equal (@period_start + 7.days).to_i, result.current_period_end.to_i
    end

    test "rejects auto_renew off without usage in current period even if drinks_used counter set" do
      error = assert_raises(AutoRenewService::Error) do
        AutoRenewService.call(subscription: @sub, auto_renew: false)
      end
      assert_match(/usage in current paid period/, error.message)
      assert @sub.reload.auto_renew
    end

    test "7d window event outside current period does not unlock auto_renew off" do
      order = Order.create!(
        tenant_id: @tenant.id,
        customer_id: @customer.id,
        customer_name: "U",
        order_number: "ar2-#{SecureRandom.hex(2)}",
        source: :mobile,
        status: :closed,
        total_amount: 119,
        discount_amount: 0,
        final_amount: 119
      )
      SubscriptionUsageEvent.create!(
        subscription_id: @sub.id,
        order_id: order.id,
        point_id: @tenant.id,
        applied_price: 119,
        savings_amount: 81,
        pricing_kind: "in_limit",
        created_at: @period_start - 1.day,
        updated_at: @period_start - 1.day
      )

      assert_raises(AutoRenewService::Error) do
        AutoRenewService.call(subscription: @sub, auto_renew: false)
      end
    end
  end
end
