# frozen_string_literal: true

require "test_helper"

class Shop::Api::EmailVerificationDbFallbackTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "db-fallback-#{SecureRandom.hex(4)}@example.com"
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
  end

  test "order succeeds when session bucket cleared but database verification remains" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body

      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
      assert ShopEmailVerification.active_for(tenant_id: @tenant.id, email: @email)

      sess.request.session.delete(Shop::EmailVerificationSession::KEY)

      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: @email, name: "DB Fallback", payment_method: "cash"),
        as: :json

      assert_equal 200, sess.response.status, sess.response.body
      assert_equal "accepted", sess.response.parsed_body["status"]
    end
  end

  test "status endpoint reports verified from database after session bucket cleared" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body

      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
      sess.request.session.delete(Shop::EmailVerificationSession::KEY)

      sess.get "/shop/api/email_otp/status",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: @email },
        as: :json

      assert_equal 200, sess.response.status, sess.response.body
      assert_equal true, sess.response.parsed_body["verified"]
      assert_equal @email, sess.response.parsed_body["email"]
    end
  end

  test "status and order succeed after browser session_id changes when email still verified in database" do
    old_session_id = nil
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body

      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
      old_session_id = sess.request.session.id.to_s
      assert ShopEmailVerification.active_for(tenant_id: @tenant.id, email: @email)
    end

    open_session do |sess|
      sess.get "/shop/api/email_otp/status",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: @email },
        as: :json

      assert_equal 200, sess.response.status, sess.response.body
      assert_equal true, sess.response.parsed_body["verified"]
      assert_equal @email, sess.response.parsed_body["email"]
      refute_equal old_session_id, sess.request.session.id.to_s

      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body

      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: @email, name: "Rotated Session", payment_method: "cash"),
        as: :json

      assert_equal 200, sess.response.status, sess.response.body
      assert_equal "accepted", sess.response.parsed_body["status"]
    end
  end
end
