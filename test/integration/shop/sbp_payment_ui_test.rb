# frozen_string_literal: true

require "test_helper"

# RED [TDD] Шаг 9: UI «Оплатить быстро» / SBP → sbp/init → redirect.
# Реализации ещё нет — ожидаем падение (missing files / assert).
class Shop::SbpPaymentUiTest < ActionDispatch::IntegrationTest
  SHEET    = Rails.root.join("app/frontend/components/PaymentMethodsSheet.svelte")
  CHECKOUT = Rails.root.join("app/frontend/routes/Checkout.svelte")
  SBP_LIB  = Rails.root.join("app/frontend/lib/shopSbpPay.js")
  I18N     = Rails.root.join("app/frontend/lib/paymentMethodI18n.js")

  test "shopSbpPay.js exists with init and redirect exports" do
    assert File.exist?(SBP_LIB), "нужен app/frontend/lib/shopSbpPay.js"
    src = File.read(SBP_LIB)
    assert_includes src, "export async function initSbpPayment"
    assert_includes src, "export function redirectToSbp"
    assert_includes src, "export function sbpPollOptions"
    assert_includes src, "/payments/sbp/init"
  end

  test "i18n exposes ctaSbpFastPay Оплатить быстро" do
    src = File.read(I18N)
    assert_includes src, "export function ctaSbpFastPay"
    assert_includes src, "Оплатить быстро"
  end

  test "PaymentMethodsSheet SBP row disabled per #26 mock (скрин 03)" do
    src = File.read(SHEET)
    assert_includes src, 'data-testid="payment-method-sbp"'
    assert_includes src, "shopSbpPay"
    assert_match(
      /data-testid="payment-method-sbp"[\s\S]{0,120}?^\s*disabled\s*$/m,
      src,
      "СБП disabled по канону #26; deep link #27 — follow-up"
    )
  end

  test "Checkout wires SBP pay via shopSbpPay" do
    src = File.read(CHECKOUT)
    assert_includes src, "shopSbpPay"
    assert_includes src, "initSbpPayment"
    assert_includes src, "savePendingOrder"
  end
end
