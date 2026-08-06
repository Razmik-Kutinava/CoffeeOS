# frozen_string_literal: true

require "test_helper"

# Баг 2026-08-06: при has_active_order hideCartTail прятал peek корзины —
# add на карточке товара «пропадал» (статус есть, корзины нет).
# Канон: OrderStatusSheet + cart lines — секции одной CartSheet (стык, не mutex).
class Shop::ActiveOrderCartPeekStackTest < ActionDispatch::IntegrationTest
  def sheet
    @sheet ||= File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
  end

  def thresholds
    @thresholds ||= File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))
  end

  test "CartSheet mounts OrderStatusSheet embedded inside one sheet" do
    assert_includes sheet, "<OrderStatusSheet"
    assert_includes sheet, "embedded={true}"
    assert_includes sheet, 'data-testid="shop-cart-sheet"'
  end

  test "cart peek branches render when items present (no hideCartTail mutex)" do
    refute_includes sheet, "hideCartTail",
      "mutex hideCartTail убран — статус не вытесняет корзину"

    assert_match(/mode === MODE_PEEK \|\| payStackActive\) && count >= 2/, sheet)
    assert_match(/mode === MODE_EXPANDED && count >= 2/, sheet)
    assert_match(/:else if singleItem/, sheet)
  end

  test "height grows by STATUS_IN_SHEET_EXTRA_VH when hasActiveOrder and cart has items" do
    assert_includes thresholds, "STATUS_IN_SHEET_EXTRA_VH"
    assert_match(
      /hasActiveOrderFlag[\s\S]*?STATUS_IN_SHEET_EXTRA_VH|STATUS_IN_SHEET_EXTRA_VH[\s\S]*?hasActiveOrderFlag/,
      sheet
    )
  end

  test "empty placeholder hidden under active order without cart lines" do
    assert_match(
      /#if !showRepeat && !hasActiveOrderFlag[\s\S]*?тут будут твои заказы/,
      sheet
    )
  end

  test "build marker bumped for Fly verify" do
    assert_includes thresholds, 'CART_SHEET_BUILD = "prog38"'
  end
end
