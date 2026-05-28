# frozen_string_literal: true

require "test_helper"

class Callbacks::TbankControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"]     = "TestPassword"

    @tenant = create_tenant!

    @order = Order.create!(
      tenant:          @tenant,
      order_number:    "ORD-#{SecureRandom.hex(3)}",
      source:          "mobile",
      status:          "pending_payment",
      total_amount:    500,
      discount_amount: 0,
      final_amount:    500
    )

    @payment = Payment.create!(
      order:               @order,
      tenant:              @tenant,
      amount:              500,
      method:              "card",
      provider:            "tbank",
      provider_payment_id: "tbank_pay_777",
      status:              "pending"
    )
  end

  teardown do
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def tbank_payload(status: "CONFIRMED", payment_id: "tbank_pay_777", order_id: nil)
    p = {
      "TerminalKey" => "TestTerminal",
      "OrderId"     => (order_id || @order.id).to_s,
      "PaymentId"   => payment_id,
      "Status"      => status,
      "Amount"      => 50000
    }
    p["Token"] = Payments::TbankAdapter.new.build_token(p)
    p
  end

  def post_notify(payload)
    post "/callbacks/tbank",
      params: payload.to_json,
      headers: { "Content-Type" => "application/json" }
  end

  # ---------------------------------------------------------------------------
  # Auth
  # ---------------------------------------------------------------------------

  test "returns 401 for invalid token" do
    payload = tbank_payload
    payload["Token"] = "badhash"
    post_notify(payload)
    assert_response :unauthorized
  end

  test "returns 400 for empty body" do
    post "/callbacks/tbank", params: "", headers: { "Content-Type" => "application/json" }
    assert_response :bad_request
  end

  # ---------------------------------------------------------------------------
  # CONFIRMED → order accepted
  # Заказ без items → OrderRecipeDeduction вернёт early
  # ---------------------------------------------------------------------------

  test "CONFIRMED transitions order to accepted and payment to succeeded" do
    post_notify(tbank_payload(status: "CONFIRMED"))
    assert_response :ok
    assert_equal "succeeded", @payment.reload.status
    assert_equal "accepted",  @order.reload.status
  end

  test "CONFIRMED stores provider_payment_id on payment" do
    post_notify(tbank_payload(status: "CONFIRMED"))
    assert_equal "tbank_pay_777", @payment.reload.provider_payment_id
  end

  test "CONFIRMED response body contains ok: true" do
    post_notify(tbank_payload(status: "CONFIRMED"))
    assert_equal true, JSON.parse(response.body)["ok"]
  end

  # ---------------------------------------------------------------------------
  # REJECTED → payment failed, order stays pending
  # ---------------------------------------------------------------------------

  test "REJECTED transitions payment to failed, order stays pending_payment" do
    post_notify(tbank_payload(status: "REJECTED"))
    assert_response :ok
    assert_equal "failed",          @payment.reload.status
    assert_equal "pending_payment", @order.reload.status
  end

  # ---------------------------------------------------------------------------
  # Ignored statuses
  # ---------------------------------------------------------------------------

  test "FORM_SHOWED returns ok without changing payment status" do
    post_notify(tbank_payload(status: "FORM_SHOWED"))
    assert_response :ok
    assert_equal "pending", @payment.reload.status
  end

  # ---------------------------------------------------------------------------
  # Payment not found
  # ---------------------------------------------------------------------------

  test "returns 404 when payment not found" do
    post_notify(tbank_payload(order_id: 999999, payment_id: "no_such_id"))
    assert_response :not_found
  end
end
