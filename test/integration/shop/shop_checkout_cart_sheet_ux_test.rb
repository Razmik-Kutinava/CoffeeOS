# frozen_string_literal: true

require "test_helper"

# Эталон заказчика: на #/checkout видна шторка заказа (CartSheet) под шторкой оплаты.
class Shop::ShopCheckoutCartSheetUxTest < ActionDispatch::IntegrationTest
  STORE = Rails.root.join("app/frontend/lib/cartSheetStore.js")
  SHEET = Rails.root.join("app/frontend/components/CartSheet.svelte")
  CHECKOUT = Rails.root.join("app/frontend/routes/Checkout.svelte")
  PAY = Rails.root.join("app/frontend/components/PaymentMethodsSheet.svelte")

  test "isCartSheetRoute and isCheckoutRoute cover checkout" do
    src = File.read(STORE)
    assert_includes src, "export function isCartSheetRoute"
    assert_includes src, "export function isCheckoutRoute"
    assert_includes src, 'h === "/checkout"'
    assert_includes src, "ensureCheckoutCartPeek"
    assert_includes src, "CHECKOUT_PAY_EVENT"
    assert_includes src, "requestCheckoutPay"
  end

  test "CartSheet on checkout requests pay instead of push checkout" do
    src = File.read(SHEET)
    assert_includes src, "isCheckoutRoute"
    assert_includes src, "goCheckoutOrPay"
    assert_includes src, "requestCheckoutPay"
    assert_includes src, "onCheckout"
  end

  test "Checkout ensures cart peek and listens for pay event" do
    src = File.read(CHECKOUT)
    assert_includes src, "ensureCheckoutCartPeek"
    assert_includes src, "CHECKOUT_PAY_EVENT"
    assert_includes src, "checkout-page"
    assert_includes src, "checkoutPadClass"
    assert_includes src, "pb-[32vh]"
    assert_includes src, "PaymentMethodsSheet"
  end

  test "PaymentMethodsSheet sits above CartSheet z-index" do
    pay = File.read(PAY)
    assert_includes pay, "z-index: 56"
    assert_includes pay, "z-index: 55"
    sheet = File.read(SHEET)
    assert_includes sheet, "z-50"
  end
end
