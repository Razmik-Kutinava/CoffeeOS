# frozen_string_literal: true

require "test_helper"

class Subscriptions::CancelServiceTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @customer = create_mobile_customer!(email: "sub-cancel-#{SecureRandom.hex(3)}@ex.com")
    @plan = SubscriptionPlan.create!(
      code: "cancel_#{SecureRandom.hex(2)}",
      price: 499,
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
      price_at_period_start: 499,
      discount_percent_at_period_start: 20,
      current_period_start: @period_start,
      current_period_end: @period_start + 7.days
    )
  end

  teardown { Current.reset }

  test "cancels without usage in period and enqueues Telegram alert for manual refund" do
    assert_enqueued_with(job: TelegramAlertJob) do
      result = Subscriptions::CancelService.call(subscription: @sub)
      assert_equal "canceled", result.status
      assert_equal false, result.auto_renew
    end
  end

  test "cancels with usage in period without refund alert" do
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "U",
      order_number: "c-#{SecureRandom.hex(2)}",
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
      created_at: @period_start + 1.hour,
      updated_at: @period_start + 1.hour
    )

    assert_no_enqueued_jobs(only: TelegramAlertJob) do
      result = Subscriptions::CancelService.call(subscription: @sub)
      assert_equal "canceled", result.status
    end
  end

  test "is idempotent when already canceled" do
    @sub.update!(status: :canceled, auto_renew: false)
    result = Subscriptions::CancelService.call(subscription: @sub)
    assert_equal "canceled", result.status
  end
end
