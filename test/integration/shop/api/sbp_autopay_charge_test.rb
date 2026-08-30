# frozen_string_literal: true

require "test_helper"

# RED [TDD] #34 Шаг 3–4: POST /shop/api/payments/sbp/charge + CHARGE_DECLINED.
class Shop::Api::SbpAutopayChargeTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)
    @customer = create_mobile_customer!(email: "charge-#{SecureRandom.hex(3)}@example.com")
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
      customer_id: @customer.id,
      customer_name: "SBP Charge",
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

  def create_sbp_token!(token: "acct-charge-1")
    MobilePaymentMethod.create!(
      customer_id: @customer.id,
      payment_type: "sbp",
      card_token: token,
      card_masked: "СБП",
      is_active: true,
      is_default: true,
      last_used_at: Time.current
    )
  end

  test "routes declare POST payments/sbp/charge" do
    assert_recognizes(
      { controller: "shop/api/payments", action: "sbp_charge" },
      { path: "/shop/api/payments/sbp/charge", method: :post }
    )
  end

  test "payments controller defines sbp_charge action" do
    assert Shop::Api::PaymentsController.instance_methods(false).include?(:sbp_charge),
      "[TDD] нужен action sbp_charge"
  end

  test "POST sbp/charge returns success status for order with AccountToken" do
    create_sbp_token!
    order = build_pending_order!

    open_session do |sess|
      bind_shop_order_to_session!(sess, tenant_id: @tenant.id, order: order, email: @customer.email)
      sess.post "/shop/api/payments/sbp/charge",
        headers: shop_headers,
        params: { order_id: order.id },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = JSON.parse(sess.response.body)
      assert_includes %w[CONFIRMED succeeded paid], body["status"].to_s
      assert_equal order.id.to_s, body["order_id"].to_s
    end
  end

  test "Shop::SbpAutopayChargeService is defined for Zero-Click orchestration" do
    assert defined?(Shop::SbpAutopayChargeService),
      "[TDD] Init→ChargeQr оркестрация в Shop::SbpAutopayChargeService"
  end

  test "SbpAutopayChargeService rejects customer_id mismatch with order owner" do
    create_sbp_token!
    order = build_pending_order!
    other = create_mobile_customer!(email: "other-#{SecureRandom.hex(3)}@example.com")

    error = assert_raises(Shop::SbpAutopayChargeService::Error) do
      Shop::SbpAutopayChargeService.new(tenant: @tenant).call!(
        order_id: order.id,
        customer_id: other.id
      )
    end

    assert_equal :not_found, error.http_status
    assert order.reload.pending_payment?
  end
end
