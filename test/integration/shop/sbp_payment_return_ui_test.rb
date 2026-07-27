# frozen_string_literal: true

require "test_helper"

# RED [TDD] Шаг 11: return + polling 60s/2s на PaymentResult.
class Shop::SbpPaymentReturnUiTest < ActionDispatch::IntegrationTest
  RESULT = Rails.root.join("app/frontend/routes/PaymentResult.svelte")
  SBP_LIB = Rails.root.join("app/frontend/lib/shopSbpPay.js")

  test "shopSbpPay exports pollSbpPaymentStatus and incomplete message" do
    src = File.read(SBP_LIB)
    assert_includes src, "export async function pollSbpPaymentStatus"
    assert_includes src, "export const SBP_INCOMPLETE_MESSAGE"
    assert_includes src, "export function isSbpReturnSuccessStatus"
  end

  test "PaymentResult wires SBP poll opts not infinite loader" do
    src = File.read(RESULT)
    assert_includes src, "shopSbpPay"
    assert_includes src, "pollSbpPaymentStatus"
    assert_includes src, "SBP_INCOMPLETE_MESSAGE"
    refute_includes src, "pollAccepted"
  end

  test "PaymentResult WAITING_FOR_BANK and Я оплатил" do
    src = File.read(RESULT)
    assert_includes src, "SBP_WAITING_FOR_BANK_MESSAGE"
    assert_includes src, "SBP_I_PAID_LABEL"
    assert_includes src, 'data-testid="payment-waiting-for-bank"'
    assert_includes src, "checkOrderStatus"
  end

  test "App recovers codeblack_pending_order on visibility and cold start" do
    app = File.read(Rails.root.join("app/frontend/App.svelte"))
    pending = File.read(Rails.root.join("app/frontend/lib/codeblackPendingOrder.js"))
    assert_includes pending, 'codeblack_pending_order'
    assert_includes app, "loadPendingOrder"
    assert_includes app, "visibilitychange"
    assert_includes app, "recoverCodeblackPendingOrder"
  end
end
