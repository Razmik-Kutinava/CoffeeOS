# frozen_string_literal: true

require "test_helper"

# Канон заказчика (UserCards § Канон UX checkout): peek внизу, оплата из CartSheet, без «Оплатить →» в теле.
class Shop::ShopCheckoutCartSheetUxTest < ActionDispatch::IntegrationTest
  STORE = Rails.root.join("app/frontend/lib/cartSheetStore.js")
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
    assert_includes src, "pb-[32vh]"
    assert_includes src, "PaymentMethodsSheet"
  end

  THRESH = Rails.root.join("app/frontend/lib/cartSheetThresholds.js")

  test "PaymentMethodsSheet sits above CartSheet z-index" do
    pay = File.read(PAY)
    assert_includes pay, "z-index: 56"
    assert_includes pay, "z-index: 55"
    sheet = File.read(SHEET)
    assert_includes sheet, "z-50"
    assert_includes File.read(THRESH), 'CART_SHEET_BUILD = "prog24"'
  end
end
