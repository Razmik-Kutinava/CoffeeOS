# frozen_string_literal: true

require "test_helper"

class PaymentReturnsControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(email: "fail-return-#{SecureRandom.hex(3)}@example.com")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "FR-1",
      source: :mobile,
      status: :pending_payment,
      total_amount: 300,
      discount_amount: 0,
      final_amount: 300
    )
    @payment = Payment.create!(
      order: @order,
      tenant: @tenant,
      amount: 300,
      method: :card,
      provider: "tbank",
      status: :pending
    )
  end

  test "fail redirect without ownership does not cancel order" do
    assert_no_difference [ "OrderStatusLog.count", "AdminAuditLog.count" ] do
      get "/payment/fail", params: { order_id: @order.id }
    end

    assert_redirected_to %r{#/payment-result\?status=fail}
    assert_equal "pending_payment", @order.reload.status
    assert_equal "pending", @payment.reload.status
  end

  test "fail redirect with reconnect_token owned by guest cancels order" do
    token = Shop::GuestOrderReconnect.token_for(@order)

    assert_difference [ "OrderStatusLog.count", "AdminAuditLog.count" ], 1 do
      get "/payment/fail", params: { order_id: @order.id, reconnect_token: token }
    end

    assert_redirected_to %r{reconnect_token=}
    assert_equal "cancelled", @order.reload.status
    assert_equal "failed", @payment.reload.status
  end
end
