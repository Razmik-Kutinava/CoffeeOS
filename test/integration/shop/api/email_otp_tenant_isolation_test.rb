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
    @tenant_c = create_tenant!(slug: "otp-iso-c-#{SecureRandom.hex(3)}")
    enable_product_for_tenant!(tenant: @tenant_a, product: @product, price: 100)
    enable_product_for_tenant!(tenant: @tenant_b, product: @product, price: 200)
    enable_product_for_tenant!(tenant: @tenant_c, product: @product, price: 300)
    @email1 = "iso1-#{SecureRandom.hex(4)}@example.com"
    @email2 = "iso2-#{SecureRandom.hex(4)}@example.com"
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
  end

  test "verified email on tenant A does not allow order on tenant B in same browser session" do
    open_session do |sess|
      add_to_cart!(sess, @tenant_a)
      verify_shop_email!(tenant_id: @tenant_a.id, email: @email1, session: sess)

      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant_b.id),
        params: shop_order_params(email: @email1, name: "Cross Tenant", payment_method: "cash"),
        as: :json

      assert_equal 422, sess.response.status, sess.response.body
      assert_match(/подтвердите email/i, sess.response.parsed_body["error"].to_s)
    end
  end

  test "two emails on same tenant each verify and checkout independently" do
    open_session do |sess|
      [ @email1, @email2 ].each_with_index do |email, idx|
        add_to_cart!(sess, @tenant_a)
        verify_shop_email!(tenant_id: @tenant_a.id, email: email, session: sess)
        create_order!(sess, @tenant_a, email: email, name: "Guest #{idx + 1}")
        assert MobileCustomer.exists?(email: email)
      end
    end
  end

  test "same email can checkout on tenant B after separate verify on B" do
    open_session do |sess|
      add_to_cart!(sess, @tenant_a)
      verify_shop_email!(tenant_id: @tenant_a.id, email: @email1, session: sess)

      create_order!(sess, @tenant_a, email: @email1, name: "Order A")
      order_a_id = JSON.parse(sess.response.body)["order_id"]

      add_to_cart!(sess, @tenant_b)
      verify_shop_email!(tenant_id: @tenant_b.id, email: @email1, session: sess)

      create_order!(sess, @tenant_b, email: @email1, name: "Order B")
      order_b_id = JSON.parse(sess.response.body)["order_id"]

      assert_not_equal order_a_id, order_b_id
      assert_equal @tenant_a.id, Order.find(order_a_id).tenant_id
      assert_equal @tenant_b.id, Order.find(order_b_id).tenant_id
    end
  end

  test "order history on tenant A does not include orders from tenant B for same email" do
    open_session do |sess|
      add_to_cart!(sess, @tenant_a)
      verify_shop_email!(tenant_id: @tenant_a.id, email: @email1, session: sess)
      create_order!(sess, @tenant_a, email: @email1, name: "Only A")
      order_a_id = JSON.parse(sess.response.body)["order_id"]

      sess.get "/shop/api/orders/history",
        headers: shop_tenant_headers(@tenant_a.id),
        params: { today: 1 },
        as: :json
      ids_a = sess.response.parsed_body.map { |r| r["id"] }
      assert_includes ids_a, order_a_id

      sess.get "/shop/api/orders/history",
        headers: shop_tenant_headers(@tenant_b.id),
        params: { today: 1 },
        as: :json
      assert_empty sess.response.parsed_body

      add_to_cart!(sess, @tenant_b)
      verify_shop_email!(tenant_id: @tenant_b.id, email: @email1, session: sess)
      create_order!(sess, @tenant_b, email: @email1, name: "Only B")
      order_b_id = JSON.parse(sess.response.body)["order_id"]

      sess.get "/shop/api/orders/history",
        headers: shop_tenant_headers(@tenant_b.id),
        params: { today: 1 },
        as: :json
      ids_b = sess.response.parsed_body.map { |r| r["id"] }
      assert_includes ids_b, order_b_id
      assert_not_includes ids_b, order_a_id
    end
  end

  test "otp status on tenant B is false after verify only on tenant A" do
    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant_a.id, email: @email1, session: sess)

      sess.get "/shop/api/email_otp/status",
        headers: shop_tenant_headers(@tenant_b.id),
        as: :json

      assert_equal 200, sess.response.status, sess.response.body
      assert_equal false, sess.response.parsed_body["verified"]
    end
  end

  test "new otp send on tenant B invalidates using old code from tenant A send" do
    open_session do |sess|
      sess.post "/shop/api/email_otp/send",
        headers: shop_tenant_headers(@tenant_a.id),
        params: { email: @email1 },
        as: :json
      assert_equal 200, sess.response.status

      clear_email_otp_cooldown!(@email1)

      sess.post "/shop/api/email_otp/send",
        headers: shop_tenant_headers(@tenant_b.id),
        params: { email: @email1 },
        as: :json
      assert_equal 200, sess.response.status

      sess.post "/shop/api/email_otp/verify",
        headers: shop_tenant_headers(@tenant_b.id),
        params: { email: @email1, code: "123456" },
        as: :json
      assert_equal 200, sess.response.status

      sess.get "/shop/api/email_otp/status",
        headers: shop_tenant_headers(@tenant_a.id),
        as: :json
      assert_equal false, sess.response.parsed_body["verified"]

      sess.get "/shop/api/email_otp/status",
        headers: shop_tenant_headers(@tenant_b.id),
        as: :json
      assert_equal true, sess.response.parsed_body["verified"]
      assert_equal @email1, sess.response.parsed_body["email"]
    end
  end

  test "third tenant is isolated from A verified session" do
    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant_a.id, email: @email2, session: sess)

      sess.get "/shop/api/email_otp/status",
        headers: shop_tenant_headers(@tenant_c.id),
        as: :json
      assert_equal false, sess.response.parsed_body["verified"]
    end
  end

  private

  def add_to_cart!(sess, tenant)
    sess.post "/shop/api/cart/add",
      headers: shop_tenant_headers(tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_equal 200, sess.response.status, sess.response.body
  end

  def create_order!(sess, tenant, email:, name:)
    sess.post "/shop/api/orders",
      headers: shop_tenant_headers(tenant.id),
      params: shop_order_params(email: email, name: name, payment_method: "cash"),
      as: :json
    assert_equal 200, sess.response.status, sess.response.body
  end
end
