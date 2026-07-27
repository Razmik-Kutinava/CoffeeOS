# frozen_string_literal: true

require "test_helper"

# GREEN [TDD] Шаг 3: POST /shop/api/payments/sbp/init → { payment_url }.
class Shop::Api::SbpPaymentInitTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)

    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
  end

  teardown do
    Current.reset
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
  end

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  def build_pending_order!
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_name: "SBP API Guest",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    OrderItem.create!(
      order_id: order.id,
      product_id: @product.id,
      product_name: "Латте",
      quantity: 1,
      unit_price: 200,
      total_price: 200
    )
    Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: 200,
      method: :sbp,
      provider: "tbank",
      status: :pending
    )
    order
  end

  test "POST sbp/init returns payment_url for pending order" do
    order = build_pending_order!

    post "/shop/api/payments/sbp/init",
      headers: shop_headers,
      params: { order_id: order.id },
      as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body["payment_url"].to_s.start_with?("https://qr.nspk.ru/"), body.inspect
  end

  test "POST sbp/init returns 404 when order missing" do
    post "/shop/api/payments/sbp/init",
      headers: shop_headers,
      params: { order_id: SecureRandom.uuid },
      as: :json

    assert_response :not_found
  end

  test "POST sbp/init returns 422 when order not pending_payment" do
    order = build_pending_order!
    order.update_columns(status: "accepted")

    post "/shop/api/payments/sbp/init",
      headers: shop_headers,
      params: { order_id: order.id },
      as: :json

    assert_response :unprocessable_entity
  end

  test "routes declare POST payments/sbp/init" do
    assert_recognizes(
      { controller: "shop/api/payments", action: "sbp_init" },
      { path: "/shop/api/payments/sbp/init", method: :post }
    )
  end

  test "payments controller defines sbp_init action" do
    src = File.read(Rails.root.join("app/controllers/shop/api/payments_controller.rb"))
    assert_match(/\bdef sbp_init\b/, src)
  end
end
