# frozen_string_literal: true

require "test_helper"

# #37 шаг 4 — GET /shop/api/orders/:id/wallet_pass [RED / TDD]
class Shop::Api::WalletPassTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    ENV["WALLET_SIMULATE"] = "1"
    @tenant = create_tenant!
    @customer = create_mobile_customer!(email: "wallet-pass-#{SecureRandom.hex(3)}@example.com")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Wallet",
      order_number: "202608-3704",
      source: :mobile,
      status: :preparing,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
  end

  teardown do
    ENV.delete("WALLET_SIMULATE")
    ENV.delete("WALLET_FORCE_UNAVAILABLE")
    ENV.delete("WALLET_FORCE_GEN_ERROR")
  end

  test "#37 GET wallet_pass returns pkpass blob for session customer" do
    verify_shop_email!(tenant_id: @tenant.id, email: @customer.email)

    get "/shop/api/orders/#{@order.id}/wallet_pass",
        headers: shop_tenant_headers(@tenant.id)

    assert_response :success
    assert_match(%r{application/vnd\.apple\.pkpass}, response.media_type.to_s)
    assert_operator response.body.bytesize, :>, 0
  end

  test "#37 GET wallet_pass 404 for foreign order" do
    other = create_mobile_customer!(email: "wallet-other-#{SecureRandom.hex(3)}@example.com")
    verify_shop_email!(tenant_id: @tenant.id, email: other.email)

    get "/shop/api/orders/#{@order.id}/wallet_pass",
        headers: shop_tenant_headers(@tenant.id)

    assert_response :not_found
  end

  # --- #38 шаг 3 [TDD-RED] ---

  test "#38 GET wallet_pass 500 JSON when certificate/generation fails" do
    verify_shop_email!(tenant_id: @tenant.id, email: @customer.email)
    ENV["WALLET_FORCE_GEN_ERROR"] = "1"

    get "/shop/api/orders/#{@order.id}/wallet_pass",
        headers: shop_tenant_headers(@tenant.id)

    assert_response :internal_server_error
    body = JSON.parse(response.body)
    assert body["error"].present?
    assert_match(/wallet|cert|generation|forced/i, body["error"])
  end
end
