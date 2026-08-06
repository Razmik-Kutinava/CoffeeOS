# frozen_string_literal: true

require "test_helper"

# Дефолт пустой шторки = peek + «тут будут твои заказы» (заказчик 2026-07-24).
class Shop::CartSheetDefaultPeekEmptyTest < ActionDispatch::IntegrationTest
  def store
    @store ||= File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))
  end

  def sheet
    @sheet ||= File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
  end

  def thresholds
    @thresholds ||= File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))
  end

  test "empty cart defaults to MODE_PEEK not MODE_EMPTY height collapse" do
    assert_includes store, "export const cartSheetMode = writable(MODE_PEEK)"
    assert_match(
      /if \(!items\.length\) \{\s*\/\/[^\n]*\s*cartSheetMode\.set\(MODE_PEEK\)/,
      store
    )
    assert_includes store, "Без товаров — всегда peek"
  end

  test "empty peek height matches peekSingle; build prog35" do
    assert_includes thresholds, "empty:         34"
    assert_includes thresholds, "peekSingle:    34"
    assert_includes thresholds, 'CART_SHEET_BUILD = "prog37"'
  end

  test "CartSheet empty height uses peekSingle or peekSingleWithRepeat" do
    assert_includes sheet, "if (!count)"
    assert_includes sheet, "SHEET_VH.peekSingle"
    assert_includes sheet, "SHEET_VH.peekSingleWithRepeat"
    assert_includes sheet, "тут будут твои заказы"
    # Высота empty: с repeat → peekSingleWithRepeat, иначе peekSingle (через showRepeat / frequentCount)
    gated = sheet.include?("showRepeat") || sheet.include?("frequentCount === 0")
    assert gated, "empty height должна ветвиться по showRepeat / frequentCount"
  end
end
