# frozen_string_literal: true

require "test_helper"

# Заказчик 2026-07-23: свайп шторки чувствительнее — весь прямоугольник полосы.
class Shop::CartSheetGestureHitAreaTest < ActionDispatch::IntegrationTest
  test "gesture zone is a tall full-width strip not just the hook" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-sheet-gesture-zone"'
    assert_includes sheet, 'data-gesture-hit-area="full-strip"'
    assert_includes sheet, "min-h-20"
    assert_includes sheet, "w-full"
    refute_includes sheet, "min-h-14", "устаревшая узкая зона — заказчик просил весь прямоугольник"
  end

  test "swipe threshold is more sensitive than 32px" do
    thresholds = File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))

    assert_includes thresholds, "SWIPE_UP_PX = 20"
    refute_includes thresholds, "SWIPE_UP_PX = 32"
    assert_includes thresholds, 'CART_SHEET_BUILD = "prog33"'
  end
end
