# frozen_string_literal: true

require "test_helper"

# RED/GREEN Шаг 10: маска **** 1234 + 1-tap already wired.
class Shop::SbpCardMaskStep10Test < ActionDispatch::IntegrationTest
  I18N = Rails.root.join("app/frontend/lib/paymentMethodI18n.js")
  SHEET = Rails.root.join("app/frontend/components/PaymentMethodsSheet.svelte")
  CHECKOUT = Rails.root.join("app/frontend/routes/Checkout.svelte")

  test "i18n exports formatMaskedPan **** last4" do
    src = File.read(I18N)
    assert_includes src, "export function formatMaskedPan"
    assert_includes src, "**** "
  end

  test "PaymentMethodsSheet uses Картой *mask for saved cards (#26)" do
    src = File.read(SHEET)
    assert_includes src, "formatCardMaskStar"
    assert_includes src, "labelCardBy"
    assert_includes src, 'data-testid="payment-method-card-'
  end

  test "Checkout one_click path still wired for 1-tap" do
    src = File.read(CHECKOUT)
    assert_includes src, "/payments/one_click"
    assert_includes src, "card_id"
    assert_includes src, "isInvalidRebillPaymentError"
  end
end
