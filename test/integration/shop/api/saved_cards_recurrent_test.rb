# frozen_string_literal: true

require "test_helper"

class Shop::Api::SavedCardsRecurrentTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "recurrent-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    @card = MobilePaymentMethod.create!(
      customer_id: @customer.id,
      card_token: "rebill-test-token",
      card_masked: "430000******0777",
      card_brand: "Visa",
      payment_type: "card",
      is_active: true,
      is_default: true
    )
    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
  end

  teardown do
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
  end

  test "GET saved_cards returns primary card for session customer" do
    open_session do |sess|
      bind_customer_session!(sess)

      sess.get "/shop/api/saved_cards", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
      assert_equal 200, sess.response.status

      body = JSON.parse(sess.response.body)
      assert_equal @card.id, body.dig("primary", "id")
      assert_equal "Visa", body.dig("primary", "payment_system")
      assert_equal "430000******0777", body.dig("primary", "masked_pan")
      assert_equal 1, body["cards"].size
    end
  end

  test "callback job saves card token from RebillId" do
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Webhook Guest",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 179,
      discount_amount: 0,
      final_amount: 179
    )
    payment = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: 179,
      method: :card,
      provider: "tbank",
      status: :pending,
      provider_payment_id: "pay-1"
    )

    adapter = Payments::TbankAdapter.new
    payload = {
      "TerminalKey" => "TestTerminal",
      "OrderId" => order.id.to_s,
      "PaymentId" => "pay-1",
      "Status" => "CONFIRMED",
      "RebillId" => "webhook-rebill-1",
      "Pan" => "430000******0999"
    }
    payload["Token"] = adapter.build_token(payload)

    assert_difference -> { MobilePaymentMethod.count }, 1 do
      Payments::TbankCallbackJob.perform_now(payload)
    end

    card = MobilePaymentMethod.find_by(card_token: "webhook-rebill-1")
    assert_equal "430000******0999", card.card_masked
    assert payment.reload.succeeded?
    assert order.reload.accepted?
  end

  private

  def bind_customer_session!(sess)
    sess.post "/shop/api/cart/add",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
    sess.post "/shop/api/orders",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: shop_order_params(email: @email, name: "Bind", payment_method: "cash"),
      as: :json
  end
end
