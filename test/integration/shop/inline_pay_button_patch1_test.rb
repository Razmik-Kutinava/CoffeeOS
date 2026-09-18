# frozen_string_literal: true

require "test_helper"

# Патч 1 (2026-09-17): статусы inline-оплаты внутри главной pay-кнопки Quick Repeat.
class Shop::InlinePayButtonPatch1Test < ActiveSupport::TestCase
  test "RepeatSection renders PROCESSING status inside shop-repeat-card-pay" do
    section = File.read(Rails.root.join("app/frontend/components/RepeatSection.svelte"))

    assert_includes section, 'data-testid="shop-repeat-card-pay"'
    assert_match(/cardPayLabel|inlinePayButtonLabel|payUi\.statusText/, section)
    assert_match(/bg-green-600|SUCCESS/, section)
    assert_match(/bg-red-600|ERROR/, section)
  end

  test "InlinePayFallback supports host-button status (no duplicate bar)" do
    fb = File.read(Rails.root.join("app/frontend/components/InlinePayFallback.svelte"))
    assert_match(/statusInHostButton|hideStatusBar/, fb)
  end

  test "shopInlinePayFsm patch v1 copy for 1051 and rotation" do
    fsm = File.read(Rails.root.join("app/frontend/lib/shopInlinePayFsm.js"))
    assert_includes fsm, "Платеж принимается от банка..."
    assert_includes fsm, 'INLINE_INSUFFICIENT_FUNDS_LABEL = "Недостаточно средств"'
    assert_includes fsm, 'INLINE_GENERIC_ERROR_LABEL = "Ошибка оплаты"'
  end

  test "widgetRepeatPayFlow resets ERROR and timeout to IDLE after 3000ms" do
    flow = File.read(Rails.root.join("app/frontend/lib/widgetRepeatPayFlow.js"))
    assert_match(/kind === ["']timeout["'][\s\S]*resetAfterMs\s*=\s*TBANK_INLINE_ERROR_RESET_MS/, flow)
    assert_includes flow, "INLINE_TIMEOUT_LABEL"
    assert_operator flow.scan(/resetAfterMs\s*=\s*TBANK_INLINE_ERROR_RESET_MS/).size, :>=, 4
  end
end
