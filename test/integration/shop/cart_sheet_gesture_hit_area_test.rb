# frozen_string_literal: true

require "test_helper"

# Заказчик 2026-07-23: свайп шторки чувствительнее — весь прямоугольник полосы.
class Shop::CartSheetGestureHitAreaTest < ActionDispatch::IntegrationTest
  # Заказчик 2026-10-07 (скрин): полоса с ручкой слишком толстая — тонкая на всех экранах.
  test "gesture zone is a thin full-width strip and sheet is shorter by the saved height" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    thresholds = File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))

    assert_includes sheet, 'data-testid="shop-cart-sheet-gesture-zone"'
    assert_includes sheet, 'data-gesture-hit-area="full-strip"'
    assert_includes sheet, "w-full min-h-6"
    refute_includes sheet, "min-h-20", "толстая полоса 80px — заказчик просил тонкую"
    assert_includes thresholds, "GESTURE_ZONE_SAVED_PX = 56"
    assert_includes sheet, "GESTURE_ZONE_SAVED_PX"
  end

  test "swipe threshold is more sensitive than 32px" do
    thresholds = File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))

    assert_includes thresholds, "SWIPE_UP_PX = 20"
    refute_includes thresholds, "SWIPE_UP_PX = 32"
    assert_includes thresholds, 'CART_SHEET_BUILD = "prog38"'
  end
end
