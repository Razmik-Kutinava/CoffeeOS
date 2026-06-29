# frozen_string_literal: true

require "test_helper"

# B1.13-S2 прогон 5 — канон жестов и раскладок по макетам заказчика.
class Shop::B113S2LayoutGesturesTest < ActionDispatch::IntegrationTest
  test "expanded layout store and cache exported" do
    store = File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))
    cache = File.read(Rails.root.join("app/frontend/lib/cartSheetLayoutCache.js"))
    thresholds = File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))

    assert_includes store, "cartSheetExpandedLayout"
    assert_includes store, "EXPANDED_LAYOUT_VERTICAL"
    assert_includes store, "EXPANDED_LAYOUT_HORIZONTAL"
    assert_includes cache, "coffeeos_shop_cart_sheet_layout_v1"
    assert_includes thresholds, "expandedMultiHorizontal"
  end

  test "expanded single item uses horizontal layout marker" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-expanded-single"'
    assert_includes sheet, "singleItem"
  end

  test "expanded multi vertical list layout marker" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-cart-layout="vertical"'
    assert_includes sheet, 'data-testid="shop-cart-expanded-line"'
  end

  test "expanded multi horizontal layout after swipe up" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-expanded-horizontal"'
    assert_includes sheet, "expandedHorizontal"
    assert_includes sheet, 'data-cart-sheet-layout={expandedLayout}'
  end

  test "peek horizontal thumbnails only for catalog scroll path" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    store = File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))

    assert_includes sheet, 'data-testid="shop-cart-peek-line"'
    assert_includes store, "lines <= 1"
    assert_includes store, "MODE_HIDDEN"
  end

  test "hidden vertical heads for all lines" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-hidden-heads"'
    assert_includes sheet, 'data-testid="shop-cart-hidden-head"'
  end

  test "gestures on drag handle swipe up and down" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    store = File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))

    assert_includes sheet, 'data-testid="shop-cart-sheet-drag-handle"'
    assert_includes store, "export function collapseFromSwipe"
    assert_includes store, "export function expandFromSwipe"
  end

  test "expandFromSwipe mirror hidden and peek restore expanded vertical" do
    assert_equal ["expanded", "vertical"], expand_mirror(1, "hidden", "vertical")
    assert_equal ["expanded", "vertical"], expand_mirror(2, "hidden", "vertical")
    assert_equal ["expanded", "vertical"], expand_mirror(2, "peek", "vertical")
  end

  test "expandFromSwipe mirror multi vertical to horizontal" do
    assert_equal ["expanded", "horizontal"], expand_mirror(2, "expanded", "vertical")
    assert_equal ["expanded", "vertical"], expand_mirror(1, "expanded", "vertical")
    assert_equal ["expanded", "horizontal"], expand_mirror(2, "expanded", "horizontal")
  end

  test "collapseFromSwipe mirror one item expanded to hidden" do
    assert_equal ["hidden", "vertical"], collapse_mirror(1, "expanded", "vertical")
    assert_equal ["hidden", "vertical"], collapse_mirror(1, "expanded", "horizontal")
  end

  test "collapseFromSwipe mirror multi horizontal to vertical then hidden" do
    assert_equal ["expanded", "vertical"], collapse_mirror(2, "expanded", "horizontal")
    assert_equal ["hidden", "vertical"], collapse_mirror(2, "expanded", "vertical")
    assert_equal ["hidden", "vertical"], collapse_mirror(2, "peek", "vertical")
  end

  test "catalog scroll mirror one item skips peek" do
    assert_equal "hidden", scroll_mirror(1, "expanded", 100)
    assert_equal "peek", scroll_mirror(2, "expanded", 100)
    assert_equal "hidden", scroll_mirror(2, "expanded", 200)
  end

  private

  def expand_mirror(lines, mode, layout)
    return [mode, layout] if lines.zero?

    if mode == "hidden" || mode == "peek"
      return ["expanded", "vertical"]
    end
    if mode == "expanded" && lines >= 2 && layout == "vertical"
      return ["expanded", "horizontal"]
    end

    [mode, layout]
  end

  def collapse_mirror(lines, mode, layout)
    if mode == "expanded"
      return ["hidden", "vertical"] if lines <= 1
      return ["expanded", "vertical"] if layout == "horizontal"
      return ["hidden", "vertical"]
    end
    return ["hidden", "vertical"] if mode == "peek"

    [mode, layout]
  end

  def scroll_mirror(lines, mode, delta)
    return mode if delta.negative?

    return "hidden" if delta >= 200
    if mode == "expanded" && delta >= 100
      return "hidden" if lines <= 1

      return "peek"
    end
    mode
  end
end
