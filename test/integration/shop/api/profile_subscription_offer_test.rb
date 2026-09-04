# frozen_string_literal: true

require "test_helper"

# #77 [TDD][RED] profile/config eligibility + engagement signal hooks + pwa_install
class Shop::Api::ProfileSubscriptionOfferTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!
    @email = "offer-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    @settings = SubscriptionOfferSetting.create!(
      point_id: @tenant.id,
      enabled: true,
      second_cta_mode: "subscription",
      min_completed_orders: 1,
      required_signals_count: 1
    )
  end

  def login_customer!(sess)
    verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
  end

  test "profile returns eligible_for_subscription_offer false by default and preserves orders_count" do
    open_session do |sess|
      login_customer!(sess)

      Order.create!(
        tenant_id: @tenant.id,
        customer_id: @customer.id,
        customer_name: "Guest",
        order_number: "77-oc-#{SecureRandom.hex(2)}",
        source: :mobile,
        status: :accepted,
        total_amount: 50,
        discount_amount: 0,
        final_amount: 50
      )

      sess.get "/shop/api/profile", headers: shop_tenant_headers(@tenant.id), as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_includes body.keys, "eligible_for_subscription_offer"
      assert_equal false, body["eligible_for_subscription_offer"]
      assert_equal 1, body["orders_count"]
    end
  end

  test "profile eligible true after issued order and one signal" do
    Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "77-iss-#{SecureRandom.hex(2)}",
      source: :mobile,
      status: :issued,
      total_amount: 50,
      discount_amount: 0,
      final_amount: 50
    )
    @customer.update!(pwa_installed_at: Time.current)

    open_session do |sess|
      login_customer!(sess)
      sess.get "/shop/api/profile", headers: shop_tenant_headers(@tenant.id), as: :json
      assert_equal 200, sess.response.status
      assert_equal true, sess.response.parsed_body["eligible_for_subscription_offer"]
    end
  end

  test "config exposes subscription_offer enabled and second_cta_mode" do
    get "/shop/api/config", headers: shop_tenant_headers(@tenant.id)
    assert_response :success
    offer = response.parsed_body["subscription_offer"]
    assert offer, "config must include subscription_offer"
    assert_equal true, offer["enabled"]
    assert_equal "subscription", offer["second_cta_mode"]
  end

  test "config without settings returns enabled false" do
    @settings.destroy!
    get "/shop/api/config", headers: shop_tenant_headers(@tenant.id)
    assert_response :success
    offer = response.parsed_body["subscription_offer"]
    assert_equal false, offer["enabled"]
    assert_equal "tips", offer["second_cta_mode"]
  end

  test "POST pwa_install sets pwa_installed_at once" do
    open_session do |sess|
      login_customer!(sess)

      sess.post "/shop/api/pwa_install",
        headers: shop_tenant_headers(@tenant.id),
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      @customer.reload
      first = @customer.pwa_installed_at
      assert first.present?

      travel 1.hour do
        sess.post "/shop/api/pwa_install",
          headers: shop_tenant_headers(@tenant.id),
          as: :json
        assert_equal 200, sess.response.status
        @customer.reload
        assert_equal first.to_i, @customer.pwa_installed_at.to_i
      end
    end
  end

  test "push register sets push_enabled_at once" do
    ENV["FIREBASE_API_KEY"] = "test-api-key"
    ENV["FIREBASE_AUTH_DOMAIN"] = "coffeeos-test.firebaseapp.com"
    ENV["FIREBASE_PROJECT_ID"] = "coffeeos-test"
    ENV["FIREBASE_STORAGE_BUCKET"] = "coffeeos-test.appspot.com"
    ENV["FIREBASE_MESSAGING_SENDER_ID"] = "123"
    ENV["FIREBASE_APP_ID"] = "1:123:web:abc"
    ENV["FIREBASE_VAPID_KEY"] = "BTest"
    Shop::FirebaseConfig.reset_cache!

    open_session do |sess|
      login_customer!(sess)

      sess.post "/shop/api/push/register",
        headers: shop_tenant_headers(@tenant.id),
        params: { push_token: "fcm-77-a", push_enabled: true },
        as: :json
      assert_equal 200, sess.response.status
      @customer.reload
      first = @customer.push_enabled_at
      assert first.present?

      travel 1.hour do
        sess.post "/shop/api/push/register",
          headers: shop_tenant_headers(@tenant.id),
          params: { push_token: "fcm-77-b", push_enabled: true },
          as: :json
        assert_equal 200, sess.response.status
        @customer.reload
        assert_equal "fcm-77-b", @customer.push_token
        assert_equal first.to_i, @customer.push_enabled_at.to_i
      end
    end
  ensure
    Shop::FirebaseConfig.reset_cache!
  end

  test "orders email sets email_collected_at once" do
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "77-em-#{SecureRandom.hex(2)}",
      source: :mobile,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    token = Shop::GuestOrderReconnect.token_for(order)

    post "/shop/api/orders/#{order.id}/email",
      headers: shop_tenant_headers(@tenant.id),
      params: { reconnect_token: token, email: "guest-#{SecureRandom.hex(3)}@example.com", marketing_consent: false },
      as: :json
    assert_response :success, response.body
    @customer.reload
    first = @customer.email_collected_at
    assert first.present?

    travel 1.hour do
      post "/shop/api/orders/#{order.id}/email",
        headers: shop_tenant_headers(@tenant.id),
        params: { reconnect_token: token, email: "other-#{SecureRandom.hex(3)}@example.com", marketing_consent: false },
        as: :json
      assert_response :success
      @customer.reload
      assert_equal first.to_i, @customer.email_collected_at.to_i
    end
  end
end
