# frozen_string_literal: true

require "test_helper"

class Shop::Api::PushRegisterTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(email: "push-#{SecureRandom.hex(4)}@example.com")

    @old_env = %w[
      FIREBASE_API_KEY FIREBASE_AUTH_DOMAIN FIREBASE_PROJECT_ID FIREBASE_STORAGE_BUCKET
      FIREBASE_MESSAGING_SENDER_ID FIREBASE_APP_ID FIREBASE_VAPID_KEY
    ].index_with { |k| ENV[k] }

    ENV["FIREBASE_API_KEY"] = "test-api-key"
    ENV["FIREBASE_AUTH_DOMAIN"] = "coffeeos-test.firebaseapp.com"
    ENV["FIREBASE_PROJECT_ID"] = "coffeeos-test"
    ENV["FIREBASE_STORAGE_BUCKET"] = "coffeeos-test.appspot.com"
    ENV["FIREBASE_MESSAGING_SENDER_ID"] = "123456789"
    ENV["FIREBASE_APP_ID"] = "1:123:web:abc"
    ENV["FIREBASE_VAPID_KEY"] = "BTestVapidKey"
    Shop::FirebaseConfig.reset_cache!
  end

  teardown do
    @old_env.each { |k, v| ENV[k] = v }
    Shop::FirebaseConfig.reset_cache!
  end

  test "register saves push token for logged in customer" do
    category = create_category!
    product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: product, price: 150)
    email = @customer.email

    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      verify_shop_email!(tenant_id: @tenant.id, email: email, session: sess)

      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: email, name: "Push QA", payment_method: "cash"),
        as: :json
      assert_equal 200, sess.response.status

      sess.post "/shop/api/push/register",
        headers: shop_tenant_headers(@tenant.id),
        params: { push_token: "fcm-device-token-abc", push_enabled: true },
        as: :json

      assert_equal 200, sess.response.status
      body = sess.response.parsed_body
      assert_equal true, body["registered"]

      @customer.reload
      assert_equal true, @customer.push_enabled
      assert_equal "fcm-device-token-abc", @customer.push_token
    end
  end

  test "register without customer session returns unauthorized" do
    post "/shop/api/push/register",
      headers: shop_tenant_headers(@tenant.id),
      params: { push_token: "token" },
      as: :json

    assert_response :unauthorized
  end
end
