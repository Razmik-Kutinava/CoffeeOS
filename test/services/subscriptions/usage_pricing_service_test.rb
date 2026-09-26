# frozen_string_literal: true

require "test_helper"

module Subscriptions
  class UsagePricingServiceTest < ActiveSupport::TestCase
    include TestFactories

    setup do
      @tenant = create_tenant!
      Current.tenant_id = @tenant.id
      @customer = create_mobile_customer!(email: "ups-#{SecureRandom.hex(3)}@ex.com")
      @plan = SubscriptionPlan.create!(
        code: "ups_#{SecureRandom.hex(2)}",
        price: 99,
        currency: "RUB",
        period_days: 7,
        drink_limit: 2,
        discount_price_per_drink: 119,
        over_limit_discount_percent: 20,
        active: true
      )
      @sub = Subscription.create!(
        customer_id: @customer.id,
        plan_id: @plan.id,
        purchase_point_id: @tenant.id,
        status: :active,
        auto_renew: true,
        drinks_used_this_period: 99, # must NOT drive limit
        drink_limit_at_period_start: 2,
        price_at_period_start: 99,
        discount_percent_at_period_start: 20,
        current_period_start: Time.current,
        current_period_end: 7.days.from_now
      )
      @now = Time.zone.parse("2026-09-26 12:00:00")
    end

    teardown { Current.reset }

    def make_order!
      Order.create!(
        tenant_id: @tenant.id,
        customer_id: @customer.id,
        customer_name: "U",
        order_number: "ue-#{SecureRandom.hex(2)}",
        source: :mobile,
        status: :closed,
        total_amount: 200,
        discount_amount: 0,
        final_amount: 200
      )
    end

    def seed_event!(at:)
      SubscriptionUsageEvent.create!(
        subscription_id: @sub.id,
        order_id: make_order!.id,
        point_id: @tenant.id,
        applied_price: 119,
        savings_amount: 81,
        pricing_kind: "in_limit",
        created_at: at,
        updated_at: at
      )
    end

    test "in-limit quote uses events in 7d window not drinks_used_this_period" do
      seed_event!(at: @now - 1.day)
      q = UsagePricingService.quote(subscription: @sub, catalog_price: 200, at: @now)
      assert q.in_limit
      assert_equal "in_limit", q.pricing_kind
      assert_equal BigDecimal("119"), q.applied_price
      assert_equal 1, q.usage_count
    end

    test "event exactly on 7d boundary counts" do
      seed_event!(at: @now - 7.days)
      assert_equal 1, @sub.usage_count_in_rolling_window(at: @now)
    end

    test "event outside 7d window ignored" do
      seed_event!(at: @now - 7.days - 1.second)
      assert_equal 0, @sub.usage_count_in_rolling_window(at: @now)
      q = UsagePricingService.quote(subscription: @sub, catalog_price: 200, at: @now)
      assert q.in_limit
    end

    test "over-limit applies percent and rounds to ending 9" do
      seed_event!(at: @now - 1.day)
      seed_event!(at: @now - 2.days)
      q = UsagePricingService.quote(subscription: @sub, catalog_price: 250, at: @now)
      refute q.in_limit
      assert_equal "over_limit", q.pricing_kind
      # 250 * 0.8 = 200 → round down to 199
      assert_equal BigDecimal("199"), q.applied_price
    end

    test "apply! creates usage event and preserves history across period start" do
      order = make_order!
      UsagePricingService.apply!(
        subscription: @sub,
        order: order,
        point: @tenant,
        catalog_price: 200,
        at: @now
      )
      assert_equal 1, @sub.subscription_usage_events.count

      old_ids = @sub.subscription_usage_events.pluck(:id)
      @sub.start_period_from_plan!(@plan, at: @now + 7.days)
      @sub.save!
      assert_equal old_ids.sort, @sub.subscription_usage_events.reload.pluck(:id).sort
    end
  end
end
