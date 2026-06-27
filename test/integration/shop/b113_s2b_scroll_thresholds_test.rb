# frozen_string_literal: true

require "test_helper"

# B1.13-S2b прогон 1 — скролл 100px → peek, 200px → hidden (Q-rev3).
class Shop::B113S2bScrollThresholdsTest < ActionDispatch::IntegrationTest
  test "cartSheetThresholds rev2 scroll constants 100 and 200 px" do
    src = File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))

    assert_includes src, "SCROLL_TO_PEEK_PX = 100"
    assert_includes src, "SCROLL_TO_HIDDEN_PX = 200"
    refute_includes src, "SCROLL_TO_PEEK_VH"
    refute_includes src, "SCROLL_TO_HIDDEN_VH"
  end

  test "cartSheetStore uses fixed px thresholds not viewport percent" do
    store = File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))

    assert_includes store, "SCROLL_TO_PEEK_PX"
    assert_includes store, "SCROLL_TO_HIDDEN_PX"
    refute_includes store, "SCROLL_TO_PEEK_VH"
    assert_includes store, "delta >= SCROLL_TO_HIDDEN_PX"
    assert_includes store, "mode === MODE_EXPANDED && delta >= SCROLL_TO_PEEK_PX"
  end

  test "handleCatalogScroll mirror: 100 peek, 200 hidden, scroll up unchanged" do
    assert_equal "expanded", catalog_scroll_mode("expanded", 0)
    assert_equal "expanded", catalog_scroll_mode("expanded", 99)
    assert_equal "peek", catalog_scroll_mode("expanded", 100)
    assert_equal "peek", catalog_scroll_mode("expanded", 150)
    assert_equal "hidden", catalog_scroll_mode("expanded", 200)
    assert_equal "hidden", catalog_scroll_mode("peek", 200)
    assert_equal "peek", catalog_scroll_mode("peek", 150)
    assert_equal "peek", catalog_scroll_mode("peek", -10)
  end

  private

  # Зеркало app/frontend/lib/cartSheetStore.js#handleCatalogScroll (пороги S2b).
  def catalog_scroll_mode(mode, delta)
    return mode if delta.negative?

    return "hidden" if delta >= 200
    return "peek" if mode == "expanded" && delta >= 100

    mode
  end
end
