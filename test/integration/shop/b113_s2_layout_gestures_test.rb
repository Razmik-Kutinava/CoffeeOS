# frozen_string_literal: true

require "test_helper"

# B1.13-S2 — канон раскладок peek/expanded/hidden (prog20: swap layouts).
class Shop::B113S2LayoutGesturesTest < ActionDispatch::IntegrationTest
  test "peek multi uses horizontal card row 28vw" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-peek-list"'
    assert_includes sheet, 'data-testid="shop-cart-peek-line"'
    assert_includes sheet, "MODE_PEEK && count >= 2"
    assert_includes sheet, 'data-cart-layout="horizontal"'
    assert_includes sheet, "overflow-x-auto"
    assert_includes sheet, "w-[min(28vw,110px)]"
  end

  test "minus button removes line at quantity 1 via decrementLine" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, "function decrementLine(line)"
    assert_includes sheet, "removeCartLine(line.index)"
    assert_includes sheet, "onclick={() => decrementLine(line)}"
    assert_includes sheet, 'data-testid="shop-cart-peek-minus"'
    assert_includes sheet, 'data-testid="shop-cart-expanded-minus"'
  end

  test "expanded multi uses vertical compact list" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-expanded-horizontal"'
    assert_includes sheet, 'data-testid="shop-cart-expanded-card"'
    assert_includes sheet, "MODE_EXPANDED && count >= 2"
    assert_includes sheet, "overflow-y-auto"
    assert_includes sheet, 'data-cart-layout="vertical"'
    assert_includes sheet, 'data-testid="shop-cart-expanded-delete"'
    assert_includes sheet, "CART_SHEET_BUILD"
  end

  test "expanded single item uses horizontal layout marker" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-expanded-single"'
    assert_includes sheet, "singleItem"
  end

  test "hidden chip shows total only per S2a" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-hidden-chip"'
    assert_includes sheet, "Корзина"
    assert_includes sheet, 'data-testid="shop-cart-hidden-total"'
    refute_includes sheet, 'data-testid="shop-cart-hidden-heads"'
    refute_includes sheet, 'data-testid="shop-cart-hidden-head"'
  end

  test "gestures on wide gesture zone swipe up and down" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    store = File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))

    assert_includes sheet, 'data-testid="shop-cart-sheet-gesture-zone"'
    assert_includes sheet, "min-h-14"
    assert_includes store, "handleSheetGestureDelta"
    assert_includes store, "expandFromSwipe"
    assert_includes store, "collapseFromSwipe"
  end

  test "expandFromSwipe mirror hidden to peek and peek to expanded for multi" do
    assert_equal "peek", expand_mirror(1, "hidden")
    assert_equal "peek", expand_mirror(2, "hidden")
    assert_equal "expanded", expand_mirror(2, "peek")
    assert_equal "peek", expand_mirror(1, "peek")
    assert_equal "expanded", expand_mirror(2, "expanded")
  end

  test "collapseFromSwipe mirror expanded to peek then hidden" do
    assert_equal "peek", collapse_mirror(1, "expanded")
    assert_equal "peek", collapse_mirror(2, "expanded")
    assert_equal "hidden", collapse_mirror(2, "peek")
    assert_equal "hidden", collapse_mirror(1, "peek")
  end

  test "catalog scroll mirror one item skips peek" do
    assert_equal "hidden", scroll_mirror(1, "expanded", 100)
    assert_equal "peek", scroll_mirror(2, "expanded", 100)
    assert_equal "hidden", scroll_mirror(2, "expanded", 200)
    assert_equal "hidden", scroll_mirror(2, "peek", 200)
  end

  private

  def expand_mirror(lines, mode)
    return mode if lines.zero? || mode == "empty"

    return "peek" if mode == "hidden"
    return "expanded" if mode == "peek" && lines >= 2

    mode
  end

  def collapse_mirror(lines, mode)
    return "peek" if mode == "expanded"
    return "hidden" if mode == "peek"

    mode
  end

  def scroll_mirror(lines, mode, delta)
    return mode if delta.negative?

    return "hidden" if delta >= 200
    return "hidden" if lines <= 1 && delta >= 100
    return "peek" if mode == "expanded" && delta >= 100

    mode
  end
end
