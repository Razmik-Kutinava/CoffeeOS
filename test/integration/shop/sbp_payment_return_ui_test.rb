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
end
