# frozen_string_literal: true

require "test_helper"

# #78 slice-5 [TDD][RED] Shop API subscriptions: GET/POST + auto_renew; cancel/confirm 501
class Shop::Api::SubscriptionsApiTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!(slug: "sub-api-#{SecureRandom.hex(3)}")
    Current.tenant_id = @tenant.id
    @email = "sub-api-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    @plan = SubscriptionPlan.create!(
      code: "pilot_weekly_#{SecureRandom.hex(2)}",
      price: 499,
      currency: "RUB",
      period_days: 7,
      drink_limit: 5,
      discount_price_per_drink: 119,
      over_limit_discount_percent: 20,
      active: true
    )
    @payment_method = MobilePaymentMethod.create!(
      customer_id: @customer.id,
      payment_type: "card",
      card_token: "rebill-sub-api-1",
      card_masked: "*4242",
      is_active: true,
      is_default: true
    )
    FakeTbankSubscription.enable_for_test!
  end

  teardown do
    FakeTbankSubscription.disable!
    Current.reset
  end

  def shop_headers
    shop_tenant_headers(@tenant.id)
  end

  def login!(sess)
    verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
    Shop::CustomerSession.set_customer_id!(sess.session, @tenant.id, @customer.id)
  end

  def create_active_subscription!(customer: @customer, drinks_used: 0)
    Subscription.create!(
      customer_id: customer.id,
      plan_id: @plan.id,
      purchase_point_id: @tenant.id,
      payment_method_id: @payment_method.id,
      status: :active,
      auto_renew: true,
      drinks_used_this_period: drinks_used,
      drink_limit_at_period_start: 5,
      price_at_period_start: 499,
      discount_percent_at_period_start: 20,
      current_period_start: Time.current,
      current_period_end: 7.days.from_now
    )
  end

  # --- routes / contract ---

  test "routes declare subscriptions current create auto_renew cancel confirm_payment" do
    assert_recognizes(
      { controller: "shop/api/subscriptions", action: "current" },
      { path: "/shop/api/subscriptions/current", method: :get }
    )
    assert_recognizes(
      { controller: "shop/api/subscriptions", action: "create" },
      { path: "/shop/api/subscriptions", method: :post }
    )
    assert_recognizes(
      { controller: "shop/api/subscriptions", action: "update_auto_renew" },
      { path: "/shop/api/subscriptions/current/auto_renew", method: :patch }
    )
    assert_recognizes(
      { controller: "shop/api/subscriptions", action: "cancel" },
      { path: "/shop/api/subscriptions/current/cancel", method: :post }
    )
    assert_recognizes(
      { controller: "shop/api/subscriptions", action: "confirm_payment" },
      { path: "/shop/api/subscriptions/current/confirm_payment", method: :post }
    )
  end

  # --- GET current ---

  test "GET current returns 401 without session" do
    get "/shop/api/subscriptions/current", headers: shop_headers, as: :json
    assert_response :unauthorized
  end

  test "GET current returns 404 when customer has no active or past_due subscription" do
    open_session do |sess|
      login!(sess)
      sess.get "/shop/api/subscriptions/current", headers: shop_headers, as: :json
      assert_equal 404, sess.response.status, sess.response.body
    end
  end

  test "GET current returns status remaining savings period_end auto_renew" do
    sub = create_active_subscription!(drinks_used: 2)
    SubscriptionUsageEvent.create!(
      subscription_id: sub.id,
      order_id: Order.create!(
        tenant_id: @tenant.id,
        customer_id: @customer.id,
        customer_name: "U",
        order_number: "ue-#{SecureRandom.hex(2)}",
        source: :mobile,
        status: :closed,
        total_amount: 119,
        discount_amount: 0,
        final_amount: 119
      ).id,
      point_id: @tenant.id,
      applied_price: 119,
      savings_amount: 81,
      pricing_kind: "in_limit"
    )

    open_session do |sess|
      login!(sess)
      sess.get "/shop/api/subscriptions/current", headers: shop_headers, as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal sub.id, body["id"]
      assert_equal "active", body["status"]
      assert_equal 3, body["drinks_remaining"]
      assert_equal 2, body["drinks_used_this_period"]
      assert_equal 5, body["drink_limit"]
      assert_equal @plan.code, body["plan_code"]
      assert_equal true, body["auto_renew"]
      assert body["current_period_end"].present?
      assert_in_delta 81.0, body["savings_amount"].to_f, 0.01
    end
  end

  test "GET current IDOR returns 404 for other customer subscription" do
    other = create_mobile_customer!(email: "other-#{SecureRandom.hex(3)}@example.com")
    create_active_subscription!(customer: other)

    open_session do |sess|
      login!(sess)
      sess.get "/shop/api/subscriptions/current", headers: shop_headers, as: :json
      assert_equal 404, sess.response.status, sess.response.body
    end
  end

  # --- POST create ---

  test "POST subscriptions purchases via PurchaseService and returns active subscription" do
    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscriptions",
        headers: shop_headers,
        params: {
          plan_code: @plan.code,
          payment_method_id: @payment_method.id,
          auto_renew: true
        },
        as: :json
      assert_includes [ 200, 201 ], sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert body["subscription_id"].present? || body["id"].present?
      sub = Subscription.find_by!(customer_id: @customer.id)
      assert_equal "active", sub.status
      assert_equal @plan.id, sub.plan_id
      assert_equal @tenant.id, sub.purchase_point_id
    end
  end

  test "POST subscriptions rejects foreign payment_method" do
    other = create_mobile_customer!(email: "pm-#{SecureRandom.hex(3)}@example.com")
    foreign_pm = MobilePaymentMethod.create!(
      customer_id: other.id,
      payment_type: "card",
      card_token: "rebill-foreign",
      card_masked: "*1111",
      is_active: true
    )

    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscriptions",
        headers: shop_headers,
        params: { plan_id: @plan.id, payment_method_id: foreign_pm.id },
        as: :json
      assert_includes [ 404, 422 ], sess.response.status, sess.response.body
      assert_nil Subscription.find_by(customer_id: @customer.id)
    end
  end

  test "POST subscriptions rejects when customer already has active subscription" do
    create_active_subscription!

    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscriptions",
        headers: shop_headers,
        params: { plan_code: @plan.code, payment_method_id: @payment_method.id },
        as: :json
      assert_equal 422, sess.response.status, sess.response.body
      assert_match(/already active/i, sess.response.parsed_body["error"].to_s)
      assert_equal 1, Subscription.for_customer(@customer.id).where(status: :active).count
    end
  end

  test "POST subscriptions rejects inactive payment_method" do
    @payment_method.update!(is_active: false)

    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscriptions",
        headers: shop_headers,
        params: { plan_id: @plan.id, payment_method_id: @payment_method.id },
        as: :json
      assert_equal 422, sess.response.status, sess.response.body
      assert_nil Subscription.find_by(customer_id: @customer.id)
    end
  end

  # --- PATCH auto_renew ---

  test "PATCH auto_renew updates flag on current subscription" do
    create_active_subscription!

    open_session do |sess|
      login!(sess)
      sess.patch "/shop/api/subscriptions/current/auto_renew",
        headers: shop_headers,
        params: { auto_renew: false },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      assert_equal false, sess.response.parsed_body["auto_renew"]
      assert_equal false, Subscription.find_by!(customer_id: @customer.id).auto_renew
    end
  end

  # --- cancel / confirm_payment contract (501 until later slices) ---

  test "POST cancel returns 501 not_implemented slice 3" do
    create_active_subscription!

    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscriptions/current/cancel",
        headers: shop_headers,
        as: :json
      assert_equal 501, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal "not_implemented", body["error"]
      assert_equal 3, body["slice"]
    end
  end

  test "POST confirm_payment returns 501 not_implemented slice 4" do
    create_active_subscription!

    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscriptions/current/confirm_payment",
        headers: shop_headers,
        as: :json
      assert_equal 501, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal "not_implemented", body["error"]
      assert_equal 4, body["slice"]
    end
  end
end

# Stub Init+Charge for subscription purchase integration (not shop order FakeTbankInit-only).
module FakeTbankSubscription
  mattr_accessor :enabled, default: false
  mattr_accessor :provider_payment_id, default: "fake-sub-pay"

  module Override
    def init_payment(**)
      return super unless FakeTbankSubscription.enabled

      {
        payment_url: "https://pay.tbank.ru/test-sub",
        provider_payment_id: FakeTbankSubscription.provider_payment_id
      }
    end

    def charge(payment_id:, rebill_id:)
      return super unless FakeTbankSubscription.enabled

      {
        "Success" => true,
        "Status" => "CONFIRMED",
        "PaymentId" => payment_id,
        "ErrorCode" => "0"
      }
    end
  end

  def self.install!
    return if @prepended

    Payments::TbankAdapter.prepend(Override)
    @prepended = true
  end

  def self.enable_for_test!(provider_payment_id: "fake-sub-pay")
    install!
    self.enabled = true
    self.provider_payment_id = provider_payment_id
  end

  def self.disable!
    self.enabled = false
  end
end
