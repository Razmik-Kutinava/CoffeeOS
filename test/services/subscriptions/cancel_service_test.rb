# frozen_string_literal: true

require "test_helper"

class Subscriptions::CancelServiceTest < ActiveSupport::TestCase
  include TestFactories

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
    @sub = Subscription.create!(
      customer_id: @customer.id,
      plan_id: @plan.id,
      purchase_point_id: @tenant.id,
      status: :active,
      auto_renew: true,
      drinks_used_this_period: 0,
      drink_limit_at_period_start: 5,
      price_at_period_start: 499,
      discount_percent_at_period_start: 20,
      current_period_start: Time.current,
      current_period_end: 7.days.from_now
    )
  end

  teardown { Current.reset }

  test "cancels active subscription and stops auto_renew" do
    result = Subscriptions::CancelService.call(subscription: @sub)
    assert_equal "canceled", result.status
    assert_equal false, result.auto_renew
  end

  test "is idempotent when already canceled" do
    @sub.update!(status: :canceled, auto_renew: false)
    result = Subscriptions::CancelService.call(subscription: @sub)
    assert_equal "canceled", result.status
  end
end
