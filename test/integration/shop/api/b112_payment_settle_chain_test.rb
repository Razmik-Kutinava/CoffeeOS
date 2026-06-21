# frozen_string_literal: true

require "test_helper"

# B1.12 — цепочка: callback Т-Банка → order accepted → finalize API (фронт finishSuccess).
class Shop::Api::B112PaymentSettleChainTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "b112-settle-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
  end

  teardown do
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
  end

  test "tbank callback accepts order and finalize returns payment_settled" do
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Settle Guest",
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
      provider_payment_id: "pay-settle-1"
    )

    adapter = Payments::TbankAdapter.new
    payload = {
      "TerminalKey" => "TestTerminal",
      "OrderId" => order.id.to_s,
      "PaymentId" => "pay-settle-1",
      "Status" => "CONFIRMED",
      "RebillId" => "settle-rebill-1",
      "Pan" => "430000******0888"
    }
    payload["Token"] = adapter.build_token(payload)

    Payments::TbankCallbackJob.perform_now(payload)

    assert order.reload.accepted?
    assert payment.reload.succeeded?

    open_session do |sess|
      bind_customer_session!(sess, order)

      sess.post "/shop/api/orders/#{order.id}/finalize",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        as: :json

      assert_equal 200, sess.response.status
      body = JSON.parse(sess.response.body)
      assert body["payment_settled"], body.inspect
      assert_equal "accepted", body["status"]
    end
  end

  test "finalize syncs tbank payment via GetState when webhook delayed" do
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Settle Guest",
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
      provider_payment_id: "pay-settle-getstate"
    )

    adapter = fake_get_state_adapter(
      "Status" => "CONFIRMED",
      "PaymentId" => "pay-settle-getstate",
      "RebillId" => "finalize-rebill",
      "Pan" => "430000******0888"
    )

    original_new = Payments::TbankAdapter.method(:new)
    Payments::TbankAdapter.define_singleton_method(:new) { |*_args| adapter }
    begin
      open_session do |sess|
        bind_customer_session!(sess, order)

        sess.post "/shop/api/orders/#{order.id}/finalize",
          headers: { "X-Shop-Tenant" => @tenant.id.to_s },
          as: :json

        assert_equal 200, sess.response.status
        body = JSON.parse(sess.response.body)
        assert body["payment_settled"], body.inspect
        assert_equal "accepted", body["status"]
      end
    ensure
      Payments::TbankAdapter.define_singleton_method(:new, original_new)
    end

    assert order.reload.accepted?
    assert payment.reload.succeeded?
    card = MobilePaymentMethod.primary_for(@customer.id)
    assert_equal "finalize-rebill", card.card_token
  end

  test "inline checkout polls finalize and resumes after 3DS return" do
    inline = File.read(Rails.root.join("app/frontend/components/CheckoutInlinePayment.svelte"))
    lib = File.read(Rails.root.join("app/frontend/lib/shopCheckoutInlinePay.js"))
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))

    assert_includes inline, "createSettlementWatch"
    assert_includes lib, "/orders/${orderId}/finalize"
    assert_includes lib, "payment_started"
    assert_includes lib, "SAVED_CARD_RETRY_ATTEMPTS"
    assert_includes checkout, "resumeInlinePayment"
    assert_includes checkout, "payment_started"
  end

  private

  def fake_get_state_adapter(fields)
    adapter = Payments::TbankAdapter.new
    adapter.define_singleton_method(:get_payment_state) do |**|
      { "Success" => true, "ErrorCode" => "0" }.merge(fields)
    end
    adapter
  end

  def bind_customer_session!(sess, order)
    sess.post "/shop/api/cart/add",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
    sess.post "/shop/api/orders",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: shop_order_params(email: @email, name: "Bind", payment_method: "cash"),
      as: :json
    Shop::CustomerSession.set_customer_id!(sess.session, @tenant.id, order.customer_id)
  end
end
