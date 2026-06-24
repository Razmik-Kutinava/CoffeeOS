# frozen_string_literal: true

require "test_helper"

# B1.12-R3 фаза 1 — экран «Способ оплаты» (макет 8924).
class Shop::Api::B112R3PaymentMethodsTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "b112-r3-pm-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    @card = MobilePaymentMethod.create!(
      customer_id: @customer.id,
      card_token: "rebill-r3-pm",
      card_masked: "220220******5953",
      card_brand: "MIR",
      payment_type: "card",
      is_active: true,
      is_default: true
    )
  end

  test "GET saved_cards returns cards list with pan for payment sheet" do
    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.get "/shop/api/saved_cards",
        params: { email: @email },
        headers: { "X-Shop-Tenant" => @tenant.id.to_s }
      assert_equal 200, sess.response.status

      body = JSON.parse(sess.response.body)
      assert_equal @card.id, body.dig("primary", "id")
      assert_equal 1, body["cards"].size
      assert body.dig("primary", "pan").to_s.include?("5953")
    end
  end

  test "PaymentMethodsSheet matches mockup 8924 structure" do
    sheet = File.read(Rails.root.join("app/frontend/components/PaymentMethodsSheet.svelte"))
    labels = File.read(Rails.root.join("app/frontend/lib/paymentMethodLabels.js"))

    assert_includes sheet, "Способ оплаты"
    assert_includes sheet, "Новая карта"
    assert_includes sheet, "СБП"
    assert_includes sheet, "Будет позже"
    assert_includes sheet, 'data-testid="payment-method-sbp"'
    assert_includes sheet, 'aria-disabled="true"'
    assert_includes labels, "formatCardListLabel"
    assert_includes labels, "Карта"
  end

  test "Checkout uses PaymentMethodsSheet instead of legacy card tabs" do
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))
    fsm = File.read(Rails.root.join("app/frontend/lib/shopPayFsm.js"))

    assert_includes checkout, "PaymentMethodsSheet"
    assert_includes checkout, "payment-method-summary"
    assert_includes checkout, "selectSavedCard"
    assert_includes checkout, "resetPaymentFsm"
    assert_includes checkout, '"/payments/one_click"'
    refute_includes checkout, "saved-card-block"
    refute_includes checkout, '["card", "Картой"]'
    assert_includes fsm, "PAY_FSM"
    assert_includes fsm, "DEFAULT: 0"
  end
end
