# frozen_string_literal: true

require "test_helper"

# GET /shop/api/payments/status/:order_id — CODE:BLACK ревизия Шаг 3.2
class Shop::Api::PaymentStatusTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @customer = create_mobile_customer!(email: "status-guest-#{SecureRandom.hex(4)}@example.com")
  end

  teardown do
    Current.reset
  end

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  def build_order!(status:, payment_status: nil)
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Status Guest",
      order_number: "",
      source: :mobile,
      status: status,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    if payment_status
      Payment.create!(
        order_id: order.id,
        tenant_id: @tenant.id,
        amount: 200,
        method: :sbp,
        provider: "tbank",
        status: payment_status
      )
    end
    order
  end

  def get_payment_status!(order)
    result = nil
    open_session do |sess|
      bind_shop_order_to_session!(sess, tenant_id: @tenant.id, order: order, email: @customer.email)
      sess.get "/shop/api/payments/status/#{order.id}", headers: shop_headers, as: :json
      result = [ sess.response.status, JSON.parse(sess.response.body) ]
    end
    result
  end

  test "GET payments/status returns PENDING for pending_payment order" do
    order = build_order!(status: :pending_payment, payment_status: :pending)

    status, body = get_payment_status!(order)
    assert_equal 200, status
    assert_equal "PENDING", body["status"]
    assert_equal order.id, body["order_id"]
  end

  test "GET payments/status returns CONFIRMED when order accepted" do
    order = build_order!(status: :accepted, payment_status: :succeeded)

    status, body = get_payment_status!(order)
    assert_equal 200, status
    assert_equal "CONFIRMED", body["status"]
  end

  test "GET payments/status returns CANCELED when order cancelled" do
    order = build_order!(status: :cancelled)

    status, body = get_payment_status!(order)
    assert_equal 200, status
    assert_equal "CANCELED", body["status"]
  end

  test "GET payments/status returns REJECTED when payment failed" do
    order = build_order!(status: :pending_payment, payment_status: :failed)

    status, body = get_payment_status!(order)
    assert_equal 200, status
    assert_equal "REJECTED", body["status"]
  end

  test "GET payments/status 404 for unknown order" do
    get "/shop/api/payments/status/#{SecureRandom.uuid}", headers: shop_headers, as: :json

    assert_response :not_found
  end
end
