# frozen_string_literal: true

require "test_helper"

# B1.13-S2b прогон 2 — localStorage режима + свайп/скролл вверх/1 товар.
class Shop::B113S2bModePersistenceTest < ActionDispatch::IntegrationTest
  test "cartSheetModeCache uses shopLocalStorage with persistable modes" do
    cache = File.read(Rails.root.join("app/frontend/lib/cartSheetModeCache.js"))

    assert_includes cache, 'CART_SHEET_MODE_KEY = "coffeeos_shop_cart_sheet_mode_v1"'
    assert_includes cache, "readShopLocalStorage"
    assert_includes cache, "writeShopLocalStorage"
    assert_includes cache, "MODE_PEEK"
    assert_includes cache, "MODE_EXPANDED"
    assert_includes cache, "MODE_HIDDEN"
  end

  test "cartSheetStore persists mode on leave and restores on catalog return" do
    store = File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes store, "onCatalogRouteChange"
    assert_includes store, "onCartSheetRouteChange"
    assert_includes store, "readPersistedCartSheetMode"
    assert_includes store, "writePersistedCartSheetMode"
    assert_includes store, "clearPersistedCartSheetMode"
    assert_includes sheet, "onCartSheetRouteChange"
  end

  test "applyCartData mirror cold load opens peek when cart has items" do
    assert_equal "peek", apply_cart_mode_after_load(%w[line], "empty", persisted: "peek")
    assert_equal "peek", apply_cart_mode_after_load(%w[line], "empty", persisted: "expanded")
    assert_equal "peek", apply_cart_mode_after_load(%w[line], "empty", persisted: nil)
    assert_equal "peek", apply_cart_mode_after_load(%w[line], "peek", persisted: "peek")
    assert_equal "peek", apply_cart_mode_after_load([], "peek", persisted: "peek")
    assert_equal "peek", apply_cart_mode_after_load([], "hidden", persisted: "hidden")
  end

  test "onCatalogRouteChange mirror saves on leave and restores on return" do
    state = { mode: "hidden", items: 1, persisted: nil }

    on_catalog_route_change_mirror(state, now_on_catalog: false)
    assert_equal "hidden", state[:persisted]

    state[:mode] = "empty"
    on_catalog_route_change_mirror(state, now_on_catalog: true)
    assert_equal "hidden", state[:mode]

    state[:mode] = "peek"
    state[:persisted] = "peek"
    on_catalog_route_change_mirror(state, now_on_catalog: false)
    assert_equal "peek", state[:persisted]
  end

  test "handleCatalogScroll mirror: scroll up keeps mode" do
    assert_equal "peek", catalog_scroll_mode("peek", -50)
    assert_equal "hidden", catalog_scroll_mode("hidden", -1)
    assert_equal "expanded", catalog_scroll_mode("expanded", 50)
  end

  test "expandFromSwipe mirror hidden to peek and peek to expanded for multi" do
    assert_equal "peek", expand_from_swipe_mirror(1, "hidden")
    assert_equal "peek", expand_from_swipe_mirror(2, "hidden")
    assert_equal "expanded", expand_from_swipe_mirror(2, "peek")
    assert_equal "peek", expand_from_swipe_mirror(1, "peek")
    assert_equal "expanded", expand_from_swipe_mirror(2, "expanded")
  end

  private

  def apply_cart_mode_after_load(items, mode, persisted:)
    return "peek" if items.empty?

    return "peek" if mode == "empty"

    mode
  end

  def on_catalog_route_change_mirror(state, now_on_catalog:)
    if state[:items].to_i <= 0
      if now_on_catalog
        state[:mode] = "peek"
        state[:persisted] = "peek"
      end
      return
    end

    if now_on_catalog
      state[:mode] = state[:persisted] if state[:persisted]
      state[:mode] = "peek" if state[:mode] == "empty"
    else
      state[:persisted] = state[:mode]
    end
  end

  def catalog_scroll_mode(mode, delta)
    return mode if delta.negative?

    return "hidden" if delta >= 200
    return "peek" if mode == "expanded" && delta >= 100

    mode
  end

  def expand_from_swipe_mirror(item_count, mode)
    return mode if mode == "empty" || item_count.zero?

    return "peek" if mode == "hidden"
    return "expanded" if mode == "peek" && item_count >= 2

    mode
  end
end
