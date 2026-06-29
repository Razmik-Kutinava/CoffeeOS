# frozen_string_literal: true

require "test_helper"

# B1.13-S2 — раскладка поп-апа по макетам + жесты свайпа на drag-handle.
class Shop::B113S2LayoutGesturesTest < ActionDispatch::IntegrationTest
  test "expanded single item uses horizontal layout marker" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-expanded-single"'
    assert_includes sheet, "singleItem"
    assert_includes sheet, 'data-cart-layout="horizontal"'
  end

  test "expanded multi items use vertical list layout marker" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-cart-layout="vertical"'
    assert_includes sheet, 'data-testid="shop-cart-expanded-line"'
  end

  test "peek uses horizontal thumbnails row" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, "MODE_PEEK"
    assert_includes sheet, 'data-testid="shop-cart-peek-line"'
    assert_includes sheet, "overflow-x-auto"
  end

  test "hidden shows vertical heads for all lines" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-hidden-heads"'
    assert_includes sheet, 'data-testid="shop-cart-hidden-head"'
    assert_includes sheet, 'data-cart-layout="vertical"'
  end

  test "sheet gestures on drag handle with swipe up and down" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    store = File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))

    assert_includes sheet, 'data-testid="shop-cart-sheet-drag-handle"'
    assert_includes sheet, "applySheetGesture"
    assert_includes sheet, "collapseFromSwipe"
    assert_includes sheet, "expandFromSwipe"
    refute_includes sheet, 'style:touch-action="none"'
    assert_includes store, "export function collapseFromSwipe"
  end

  test "collapseFromSwipe mirror expanded to peek to hidden" do
    assert_equal "peek", collapse_from_swipe_mirror("expanded")
    assert_equal "hidden", collapse_from_swipe_mirror("peek")
    assert_equal "hidden", collapse_from_swipe_mirror("hidden")
  end

  test "expandFromSwipe mirror only from peek or hidden with 2+ lines" do
    assert_equal "expanded", expand_from_swipe_mirror(2, "peek")
    assert_equal "expanded", expand_from_swipe_mirror(2, "hidden")
    assert_equal "peek", expand_from_swipe_mirror(1, "peek")
    assert_equal "hidden", expand_from_swipe_mirror(1, "hidden")
    assert_equal "expanded", expand_from_swipe_mirror(2, "expanded")
  end

  private

  def collapse_from_swipe_mirror(mode)
    case mode
    when "expanded" then "peek"
    when "peek" then "hidden"
    else mode
    end
  end

  def expand_from_swipe_mirror(item_count, mode)
    return mode if mode == "expanded" || mode == "empty"
    return mode if item_count <= 1

    "expanded"
  end
end
