# frozen_string_literal: true

require "test_helper"

# Empty-надпись «тут будут твои заказы» только без истории заказов (frequent).
class Shop::CartSheetEmptyOrdersPlaceholderTest < ActionDispatch::IntegrationTest
  def sheet
    @sheet ||= File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
  end

  def thresholds
    @thresholds ||= File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))
  end

  test "empty placeholder only when frequentCount is zero" do
    assert_includes sheet, "тут будут твои заказы"
    assert_includes sheet, "frequentCount === 0"
    assert_match(
      /#if frequentCount === 0[\s\S]*?shop-cart-sheet-empty[\s\S]*?тут будут твои заказы/,
      sheet
    )
  end

  test "empty mode shows RepeatSection only when frequentCount > 0" do
    assert_includes sheet, "shop-repeat-slot-empty"
    assert_match(
      /#if frequentCount > 0 && !onCheckout[\s\S]*?shop-repeat-slot-empty[\s\S]*?RepeatSection/,
      sheet
    )
  end

  test "build marker prog33" do
    assert_includes thresholds, 'CART_SHEET_BUILD = "prog33"'
  end
end
