# frozen_string_literal: true

require "test_helper"

# B1.12-R3 фаза 3 — хвосты R2 + legacy iframe guard.
class Shop::Api::B112R3Phase3Test < ActionDispatch::IntegrationTest
  test "checkout does not use bank redirect or legacy iframe for card pay" do
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))
    refute_includes checkout, "redirectToBankPayment"
    refute_includes checkout, "redirectToPaymentUrl"
    refute_includes checkout, 'push("/payment")'
    refute_includes checkout, "CheckoutInlinePayment"
    assert_includes checkout, "ThreeDsOverlay"
    assert_includes checkout, '"/payments/one_click"'
  end

  test "tbankPayment.js kept for session resume only not card redirect" do
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))
    assert_includes checkout, "loadPaymentSession"
    assert_includes checkout, "savePaymentSession"
    refute_match(/redirectToBankPayment|submitThreeDsChallenge.*_self/, checkout)
  end

  test "NewCardSheet uses checkout name as CardHolder source" do
    sheet = File.read(Rails.root.join("app/frontend/components/NewCardSheet.svelte"))
    assert_includes sheet, "cardHolderName"
    assert_includes sheet, "cardHolder: cardHolderName || name"
  end

  test "TBANK_RSA documented in runbook and fly demo stand" do
    recurrent = File.read(Rails.root.join("docs/operations/milestones/veha_2/runbooks/TBANK_RECURRENT.md"))
    fly = File.read(Rails.root.join("docs/operations/demo/FLY_DEMO_STAND.md"))
    assert_includes recurrent, "TBANK_RSA_PUBLIC_KEY"
    assert_includes fly, "TBANK_RSA_PUBLIC_KEY"
  end
end
