# frozen_string_literal: true

require "test_helper"

# B1.12-R4 — single-screen checkout: без push("/payment"), inline iframe на checkout.
class Shop::Api::B112CheckoutSingleScreenTest < ActionDispatch::IntegrationTest
  test "Checkout.svelte does not navigate to payment route for iframe orders" do
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))
    refute_includes checkout, 'push("/payment")'
    assert_includes checkout, "CheckoutInlinePayment"
    assert_includes checkout, "beginInlinePayment"
  end

  test "Payment.svelte redirects legacy session to checkout" do
    payment = File.read(Rails.root.join("app/frontend/routes/Payment.svelte"))
    assert_includes payment, 'push("/checkout")'
  end

  test "CheckoutPayButton has extended pay states" do
    btn = File.read(Rails.root.join("app/frontend/components/CheckoutPayButton.svelte"))
    one_click = File.read(Rails.root.join("app/frontend/lib/shopOneClickPay.js"))
    assert_includes one_click, "ordering"
    assert_includes one_click, "awaiting"
    assert_includes btn, "Оформляем"
    assert_includes btn, "Ждём банк"
  end
end
