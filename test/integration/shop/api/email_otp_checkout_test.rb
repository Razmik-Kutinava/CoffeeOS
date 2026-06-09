# frozen_string_literal: true

require "test_helper"

class Shop::Api::EmailOtpCheckoutTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "checkout-#{SecureRandom.hex(4)}@example.com"
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
  end

  test "email otp verify then cash order" do
    post "/shop/api/cart/add",
      headers: shop_tenant_headers(@tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    post "/shop/api/orders",
      headers: shop_tenant_headers(@tenant.id),
      params: shop_order_params(email: @email, name: "Email QA", payment_method: "cash"),
      as: :json

    assert_response :success, response.body
    json = JSON.parse(response.body)
    assert_equal "accepted", json["status"]
    assert MobileCustomer.exists?(email: @email)
  end

  test "order without verified email is rejected" do
    post "/shop/api/cart/add",
      headers: shop_tenant_headers(@tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    post "/shop/api/orders",
      headers: shop_tenant_headers(@tenant.id),
      params: shop_order_params(email: @email, payment_method: "cash"),
      as: :json

    assert_response :unprocessable_entity
    assert_match(/подтвердите email/i, response.parsed_body["error"])
  end

  test "send rejects invalid email" do
    post "/shop/api/email_otp/send",
      headers: shop_tenant_headers(@tenant.id),
      params: { email: "not-an-email" },
      as: :json

    assert_response :unprocessable_entity
    assert_match(/email/i, response.parsed_body["error"].to_s)
    refute ShopEmailOtpCode.active("not-an-email").exists?
  end

  test "verify rejects wrong code and order stays blocked" do
    post "/shop/api/cart/add",
      headers: shop_tenant_headers(@tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    post "/shop/api/email_otp/send",
      headers: shop_tenant_headers(@tenant.id),
      params: { email: @email },
      as: :json
    assert_response :success

    post "/shop/api/email_otp/verify",
      headers: shop_tenant_headers(@tenant.id),
      params: { email: @email, code: "000000" },
      as: :json
    assert_response :unprocessable_entity
    assert_match(/код/i, response.parsed_body["error"].to_s)

    get "/shop/api/email_otp/status",
      headers: shop_tenant_headers(@tenant.id),
      as: :json
    assert_response :success
    assert_equal false, response.parsed_body["verified"]

    post "/shop/api/orders",
      headers: shop_tenant_headers(@tenant.id),
      params: shop_order_params(email: @email, payment_method: "cash"),
      as: :json
    assert_response :unprocessable_entity
    assert_match(/подтвердите email/i, response.parsed_body["error"].to_s)
  end
end
