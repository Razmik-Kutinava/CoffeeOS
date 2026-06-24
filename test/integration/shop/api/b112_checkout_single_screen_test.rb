# frozen_string_literal: true

require "test_helper"

# B1.12-R4/R5 — checkout: без #/payment, без inline iframe банка снизу.
class Shop::Api::B112CheckoutSingleScreenTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "b112-r5-#{SecureRandom.hex(4)}@example.com"
  end

  test "Checkout uses custom NewCardSheet instead of bank redirect" do
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))
    refute_includes checkout, 'push("/payment")'
    refute_includes checkout, "CheckoutInlinePayment"
    assert_includes checkout, "NewCardSheet"
    assert_includes checkout, "openNewCardSheet"
    refute_includes checkout, "redirectToBankPayment"
    refute_includes checkout, "redirectToPaymentUrl"
  end

  test "App.svelte has no /payment route" do
    app = File.read(Rails.root.join("app/frontend/App.svelte"))
    refute_includes app, '"/payment"'
    refute File.exist?(Rails.root.join("app/frontend/routes/Payment.svelte"))
  end

  test "Checkout blocks pay while saved cards load and one-click uses settlement wait" do
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))
    assert_includes checkout, "savedCardsLoading"
    assert_includes checkout, "async function handlePayFromSheet()"
    assert_includes checkout, "res.recurrent_charge || res.provider_payment_id"
    assert_includes checkout, "waitForOrderSettled"
    assert_includes checkout, "shopSavedCardCache"
    refute_includes checkout, "if (redirectToBankPayment(res)) return"
  end

  test "CheckoutPayButton has extended pay states" do
    btn = File.read(Rails.root.join("app/frontend/components/CheckoutPayButton.svelte"))
    one_click = File.read(Rails.root.join("app/frontend/lib/shopOneClickPay.js"))
    assert_includes one_click, "ordering"
    assert_includes one_click, "awaiting"
    assert_includes btn, "Оформляем"
    assert_includes btn, "Ждём банк"
  end

  test "card order API returns payment_url without iframe flag" do
    old_sim = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
    ENV["SHOP_PAYMENT_IFRAME"] = "1"

    klass = Payments::TbankAdapter
    orig_new = klass.method(:new)
    klass.define_singleton_method(:new) do
      inst = orig_new.call
      inst.define_singleton_method(:init_payment) do |**_kwargs|
        { payment_url: "https://securepay.tinkoff.ru/test-pay", provider_payment_id: "pay-r5-1" }
      end
      inst
    end

    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/orders",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: shop_order_params(email: @email, name: "R5", payment_method: "card"),
        as: :json

      assert_equal 200, sess.response.status
      body = JSON.parse(sess.response.body)
      assert_equal false, body["payment_iframe"]
      assert body["payment_url"].present?
      assert body["card_binding"]
    end
  ensure
    klass.define_singleton_method(:new, orig_new)
    ENV["SHOP_SIMULATE_PAYMENT"] = old_sim
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
    ENV.delete("SHOP_PAYMENT_IFRAME")
  end
end
