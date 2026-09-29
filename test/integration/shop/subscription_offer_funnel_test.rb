# frozen_string_literal: true

require "test_helper"

# TASK_96 [TDD][RED] Subtask 31–33: subscription_purchased + UTM-атрибуция + отчёт воронки
class Shop::SubscriptionOfferFunnelTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(email: "sof-#{SecureRandom.hex(4)}@example.com")
    @plan = SubscriptionPlan.create!(
      code: "funnel_weekly_#{SecureRandom.hex(2)}", price: 99, currency: "RUB", period_days: 7,
      drink_limit: 5, discount_price_per_drink: 119, over_limit_discount_percent: 20, active: true
    )
  end

  teardown { Current.reset }

  def build_payment!(extra_data = {})
    Current.tenant_id = @tenant.id
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "96-f-#{SecureRandom.hex(3)}",
      source: :mobile,
      status: :closed,
      total_amount: 99,
      discount_amount: 0,
      final_amount: 99
    )
    Payment.create!(
      tenant_id: @tenant.id,
      order_id: order.id,
      amount: 99,
      method: :card,
      status: :succeeded,
      provider: "tbank",
      provider_payment_id: "pid-96-#{SecureRandom.hex(3)}",
      provider_data: { "subscription_intent" => true, "subscription_plan_id" => @plan.id }.merge(extra_data)
    )
  end

  def log_opened!(channel:, content:, at:, type: "offer_opened")
    MarketingEvent.create!(
      event_type: type, customer_id: @customer.id, point_id: @tenant.id, channel: channel,
      utm_campaign: "subscription_offer", utm_content: content, occurred_at: at
    )
  end

  def purchased_events
    MarketingEvent.where(customer_id: @customer.id, event_type: "subscription_purchased")
  end

  def with_stub(klass, method_name, impl)
    original = klass.method(method_name)
    klass.define_singleton_method(method_name, &impl)
    yield
  ensure
    klass.define_singleton_method(method_name, original)
  end

  test "purchase without utm → attribution from last offer_opened + subscription_purchased" do
    log_opened!(channel: "banner", content: "banner_v1", at: 2.hours.ago)
    log_opened!(channel: "lk", content: "lk_v1", at: 1.hour.ago)

    subscription = Subscriptions::PaymentFulfillment.call(payment: build_payment!)

    assert_equal "lk", subscription.offer_channel
    assert_equal "subscription_offer", subscription.utm_campaign
    assert_equal "lk_v1", subscription.utm_content

    event = purchased_events.first
    assert event
    assert_equal "lk", event.channel
    assert_equal "lk_v1", event.utm_content
    assert_equal @tenant.id, event.point_id
    assert_equal subscription.id, event.metadata["subscription_id"]
  end

  test "push_opened counts as the last open for attribution" do
    log_opened!(channel: "banner", content: "banner_v1", at: 2.hours.ago)
    log_opened!(channel: "push", content: "push_v1", at: 10.minutes.ago, type: "push_opened")

    subscription = Subscriptions::PaymentFulfillment.call(payment: build_payment!)
    assert_equal "push", subscription.offer_channel
    assert_equal "push_v1", subscription.utm_content
  end

  test "utm passed with purchase wins over event attribution" do
    log_opened!(channel: "banner", content: "banner_v1", at: 1.hour.ago)

    subscription = Subscriptions::PaymentFulfillment.call(
      payment: build_payment!("utm_campaign" => "promo_x", "utm_content" => "c1", "offer_channel" => "lk")
    )
    assert_equal "lk", subscription.offer_channel
    assert_equal "promo_x", subscription.utm_campaign
    assert_equal "promo_x", purchased_events.first.utm_campaign
  end

  test "no offer_opened → purchase without attribution, event still written" do
    subscription = Subscriptions::PaymentFulfillment.call(payment: build_payment!)
    assert_nil subscription.offer_channel
    assert_equal 1, purchased_events.count
  end

  test "webhook replay → single subscription_purchased" do
    payment = build_payment!
    first = Subscriptions::PaymentFulfillment.call(payment: payment)
    second = Subscriptions::PaymentFulfillment.call(payment: payment)
    assert_equal first.id, second.id
    assert_equal 1, purchased_events.count
  end

  test "analytics failure does not roll back the purchase" do
    log_opened!(channel: "banner", content: "banner_v1", at: 1.hour.ago)

    subscription = nil
    with_stub(MarketingEvent, :create!, ->(*_a, **_k) { raise ActiveRecord::StatementInvalid, "boom" }) do
      assert_nothing_raised do
        ActiveRecord::Base.transaction { subscription = Subscriptions::PaymentFulfillment.call(payment: build_payment!) }
      end
    end

    assert subscription&.persisted?
    assert Subscription.exists?(subscription.id)
    assert_equal "purchased", SubscriptionOfferState.find_by(customer_id: @customer.id).status
  end

  test "funnel report aggregates by event_type and channel within range and point" do
    other_tenant = create_tenant!
    now = Time.current
    log_opened!(channel: "banner", content: "banner_v1", at: now - 1.day)
    log_opened!(channel: "banner", content: "banner_v1", at: now - 2.days)
    log_opened!(channel: "lk", content: "lk_v1", at: now - 1.day)
    MarketingEvent.create!(event_type: "banner_shown", customer_id: @customer.id, point_id: @tenant.id,
                           channel: "banner", occurred_at: now - 1.day)
    MarketingEvent.create!(event_type: "banner_shown", customer_id: @customer.id, point_id: @tenant.id,
                           channel: "banner", occurred_at: now - 30.days)
    MarketingEvent.create!(event_type: "banner_shown", customer_id: @customer.id, point_id: other_tenant.id,
                           channel: "banner", occurred_at: now - 1.day)

    report = Subscriptions::OfferFunnelReport.call(point_id: @tenant.id, from: now - 7.days, to: now)

    rows = report[:rows].to_h { |r| [ [ r[:event_type], r[:channel] ], r[:count] ] }
    assert_equal 2, rows[[ "offer_opened", "banner" ]]
    assert_equal 1, rows[[ "offer_opened", "lk" ]]
    assert_equal 1, rows[[ "banner_shown", "banner" ]]
    assert_equal 3, report[:totals]["offer_opened"]
    assert_equal 1, report[:totals]["banner_shown"]
  end

  test "manager JSON endpoint returns funnel for current tenant only" do
    manager = create_user!(tenant: @tenant, role_codes: %w[general_manager], email: "fun-#{SecureRandom.hex(3)}@test.com")
    log_opened!(channel: "banner", content: "banner_v1", at: 1.hour.ago)

    login_as!(manager)
    get "/manager/subscription_offer_funnel", params: { from: 1.day.ago.iso8601, to: Time.current.iso8601 },
                                              headers: { "ACCEPT" => "application/json" }
    assert_response :success
    body = response.parsed_body
    assert_equal 1, body["totals"]["offer_opened"]
    assert(body["rows"].any? { |r| r["event_type"] == "offer_opened" && r["channel"] == "banner" && r["count"] == 1 })
  end

  test "manager funnel endpoint requires login" do
    get "/manager/subscription_offer_funnel", headers: { "ACCEPT" => "application/json" }
    assert_response :redirect
  end
end
