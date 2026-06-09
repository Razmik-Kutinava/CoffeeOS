# frozen_string_literal: true

require "test_helper"

# Multi-tenant: OTP-сессия и заказы изолированы по X-Shop-Tenant.
class Shop::Api::EmailOtpTenantIsolationTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    category = create_category!
    @product = create_product!(category: category)
    @tenant_a = create_tenant!(slug: "otp-iso-a-#{SecureRandom.hex(3)}")
    @tenant_b = create_tenant!(slug: "otp-iso-b-#{SecureRandom.hex(3)}")
    enable_product_for_tenant!(tenant: @tenant_a, product: @product, price: 100)
    enable_product_for_tenant!(tenant: @tenant_b, product: @product, price: 200)
    @email = "iso-#{SecureRandom.hex(4)}@example.com"
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
  end

  test "verified email on tenant A does not allow order on tenant B in same browser session" do
    open_session do |sess|
      add_to_cart!(sess, @tenant_a)

      verify_shop_email!(tenant_id: @tenant_a.id, email: @email, session: sess)

      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant_b.id),
        params: shop_order_params(email: @email, name: "Cross Tenant", payment_method: "cash"),
        as: :json

      assert_equal 422, sess.response.status, sess.response.body
      assert_match(/подтвердите email/i, sess.response.parsed_body["error"].to_s)
    end
  end

  test "same email can checkout on tenant B after separate verify on B" do
    open_session do |sess|
      add_to_cart!(sess, @tenant_a)
      verify_shop_email!(tenant_id: @tenant_a.id, email: @email, session: sess)

      create_order!(sess, @tenant_a, name: "Order A")
      order_a_id = JSON.parse(sess.response.body)["order_id"]

      add_to_cart!(sess, @tenant_b)
      verify_shop_email!(tenant_id: @tenant_b.id, email: @email, session: sess)

      create_order!(sess, @tenant_b, name: "Order B")
      order_b_id = JSON.parse(sess.response.body)["order_id"]

      assert_not_equal order_a_id, order_b_id
      assert_equal @tenant_a.id, Order.find(order_a_id).tenant_id
      assert_equal @tenant_b.id, Order.find(order_b_id).tenant_id
    end
  end

  test "otp status on tenant B is false after verify only on tenant A" do
    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant_a.id, email: @email, session: sess)

      sess.get "/shop/api/email_otp/status",
        headers: shop_tenant_headers(@tenant_b.id),
        as: :json

      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal false, body["verified"]
    end
  end

  test "guest profile localStorage key is scoped per tenant_id in vitrina source" do
    content = File.read(Rails.root.join("app/frontend/lib/shopGuestProfile.js"))
    assert_includes content, "shop_guest_profile:${tid}"
    assert_includes content, "tenant_id"
  end

  private

  def add_to_cart!(sess, tenant)
    sess.post "/shop/api/cart/add",
      headers: shop_tenant_headers(tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_equal 200, sess.response.status, sess.response.body
  end

  def create_order!(sess, tenant, name:)
    sess.post "/shop/api/orders",
      headers: shop_tenant_headers(tenant.id),
      params: shop_order_params(email: @email, name: name, payment_method: "cash"),
      as: :json
    assert_equal 200, sess.response.status, sess.response.body
  end
end
