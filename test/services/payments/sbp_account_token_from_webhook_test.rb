# frozen_string_literal: true

require "test_helper"

# RED [TDD] #34 Шаг 2: webhook RequestKey → GetAddAccountQRState → store.
class Payments::SbpAccountTokenFromWebhookTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @customer = create_mobile_customer!(email: "wh-#{SecureRandom.hex(3)}@example.com")
    category = create_category!
    product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: product, price: 150)

    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Webhook SBP",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 150,
      discount_amount: 0,
      final_amount: 150
    )
    @payment = Payment.create!(
      order_id: @order.id,
      tenant_id: @tenant.id,
      amount: 150,
      method: :sbp,
      provider: "tbank",
      status: :pending,
      provider_payment_id: "pay-wh-1",
      provider_data: { "save_sbp_account" => true }
    )
  end

  teardown { Current.reset }

  test "SbpAccountTokenFromWebhook service is defined" do
    assert defined?(Payments::SbpAccountTokenFromWebhook),
      "[TDD] ожидается Payments::SbpAccountTokenFromWebhook"
  end

  test "call! with RequestKey fetches AccountToken and persists once" do
    autopay = Object.new
    autopay.define_singleton_method(:get_add_account_qr_state) do |request_key:|
      assert_equal "rk-wh-1", request_key
      { account_token: "acct-from-wh" }
    end

    Payments::SbpAccountTokenFromWebhook.new(autopay: autopay).call!(
      payment: @payment,
      payload: {
        "Status" => "CONFIRMED",
        "PaymentId" => "pay-wh-1",
        "RequestKey" => "rk-wh-1"
      }
    )

    row = MobilePaymentMethod.find_by(customer_id: @customer.id, payment_type: "sbp", card_token: "acct-from-wh")
    assert row, "AccountToken должен быть сохранён"
    assert row.is_active

    Payments::SbpAccountTokenFromWebhook.new(autopay: autopay).call!(
      payment: @payment,
      payload: {
        "Status" => "CONFIRMED",
        "PaymentId" => "pay-wh-1",
        "RequestKey" => "rk-wh-1"
      }
    )
    assert_equal 1, MobilePaymentMethod.where(customer_id: @customer.id, payment_type: "sbp").count
  end

  test "call! skips when save_sbp_account was not requested" do
    @payment.update!(provider_data: {})
    called = false
    autopay = Object.new
    autopay.define_singleton_method(:get_add_account_qr_state) do |**_|
      called = true
      { account_token: "should-not" }
    end

    Payments::SbpAccountTokenFromWebhook.new(autopay: autopay).call!(
      payment: @payment,
      payload: { "Status" => "CONFIRMED", "RequestKey" => "rk-x" }
    )

    assert_not called
    assert_equal 0, MobilePaymentMethod.where(customer_id: @customer.id, payment_type: "sbp").count
  end
end
