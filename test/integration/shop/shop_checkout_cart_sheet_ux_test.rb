# frozen_string_literal: true

require "test_helper"

# Канон заказчика (UserCards § Канон UX checkout): peek + stacked PaymentMethodsSheet, без inline pay.
class Shop::ShopCheckoutCartSheetUxTest < ActionDispatch::IntegrationTest
  STORE = Rails.root.join("app/frontend/lib/cartSheetStore.js")
  THRESH = Rails.root.join("app/frontend/lib/cartSheetThresholds.js")
  SHEET = Rails.root.join("app/frontend/components/CartSheet.svelte")
  CHECKOUT = Rails.root.join("app/frontend/routes/Checkout.svelte")
  PAY = Rails.root.join("app/frontend/components/PaymentMethodsSheet.svelte")
  TZ = Rails.root.join(
    "docs/operations/milestones/veha_2/requirements/customer_tasks",
    "Исправление сохранения карты в UserCards после успешной оплаты.md"
  )

  test "customer TZ declares checkout peek canon over B1.13 catalog-only" do
    tz = File.read(TZ)
    assert_includes tz, "Канон UX checkout"
    assert_includes tz, "выше"
    assert_includes tz, "B1.13"
    assert_includes tz, "Нет"
    assert_includes tz, "Оплатить →"
  end

  test "checkout route forces peek not catalog hidden mode" do
    src = File.read(STORE)
    assert_includes src, "onCartSheetRouteChange"
    assert_includes src, "isCheckoutRoute()"
    assert_includes src, "ensureCheckoutCartPeek"
    assert_match(/isCheckoutRoute\(\)[\s\S]{0,120}ensureCheckoutCartPeek/, src)
  end

  test "CartSheet on checkout requests pay instead of push checkout" do
    src = File.read(SHEET)
    assert_includes src, "isCheckoutRoute"
    assert_includes src, "goCheckoutOrPay"
    assert_includes src, "requestCheckoutPay"
    assert_includes src, "onCheckout"
  end

  test "Checkout has no inline pay button — payment via cart sheet only" do
    src = File.read(CHECKOUT)
    refute_match(/Оплатить →/, src, "не должно быть кнопки «Оплатить →» в теле Checkout")
    refute_includes src, "Способ оплаты"
    assert_includes src, "CHECKOUT_PAY_EVENT"
    assert_includes src, "openPaymentSheet"
    assert_includes src, "checkout-pay-via-cart-hint"
    assert_includes src, "PaymentMethodsSheet"
    assert_includes src, "openCheckoutPayStack"
    assert_includes src, "closeCheckoutPayStack"
  end

  test "Phase 2 stacked checkout: peek strip above payment sheet without backdrop" do
    store = File.read(STORE)
    assert_includes store, "checkoutPayOpen"
    assert_includes store, "openCheckoutPayStack"
    assert_includes store, "closeCheckoutPayStack"

    cart = File.read(SHEET)
    assert_includes cart, "data-checkout-pay-stack"
    assert_includes cart, "payStackActive"
    assert_includes cart, "shop-cart-peek-list"

    pay = File.read(PAY)
    assert_includes pay, "stacked"
    assert_includes pay, "pm-sheet--stacked"
    assert_includes pay, "data-payment-sheet-stacked"
    assert_match(/#if !stacked/, pay, "backdrop только вне stacked checkout")

    checkout = File.read(CHECKOUT)
    assert_includes checkout, "stacked={paymentSheetOpen}"

    thresh = File.read(THRESH)
    assert_includes thresh, 'CART_SHEET_BUILD = "prog38"'
    assert_includes thresh, "CHECKOUT_PAY_STACK_VH"
    assert_includes thresh, "CHECKOUT_PEEK_VH"
  end
end
