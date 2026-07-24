# frozen_string_literal: true

require "test_helper"

# B1.13-S2a прогон 3 — приёмка поп-апа с товаром в корзине (без пустой корзины / Q-rev2).
class Shop::B113S2aCartSheetAcceptanceTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "b113-s2a-#{SecureRandom.hex(3)}")
    @category = create_category!
    @product = create_product!(category: @category, slug: "b113-s2a-prod-#{SecureRandom.hex(3)}")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 320)
  end

  test "onCartAdded opens sheet in peek after add to cart" do
    store = File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))

    assert_includes store, "export function onCartAdded"
    assert_includes store, "cartSheetMode.set(MODE_PEEK)"
    assert_includes store, "CART_JUST_ADDED_KEY"
    assert_includes store, 'shop:cart-added'
  end

  test "product add navigates to catalog and dispatches cart-added" do
    product = File.read(Rails.root.join("app/frontend/routes/Product.svelte"))
    add_js = File.read(Rails.root.join("app/frontend/lib/shopCartAdd.js"))

    assert_includes product, 'push("/")'
    assert_includes add_js, 'shop:cart-added'
  end

  test "CartSheet S2a expanded card fields image name price modifiers" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-peek-list"'
    assert_includes sheet, 'data-testid="shop-cart-expanded-horizontal"'
    assert_includes sheet, 'data-testid="shop-cart-expanded-single"'
    assert_includes sheet, "line.image_url"
    assert_includes sheet, "line.product_name"
    assert_includes sheet, "line.unit_total"
    assert_includes sheet, "line.quantity"
    assert_includes sheet, "selected_modifiers"
    assert_includes sheet, "modifierLabel"
  end

  test "CartSheet lineThumb falls back to empty placeholder on image error" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_match(/onerror/, sheet)
    assert_includes sheet, 'data-testid="shop-cart-line-thumb-empty"'
    assert_includes sheet, "brokenThumbUrls"
  end

  test "CartSheet three modes exposed via data-cart-sheet-mode" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    thresholds = File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))

    assert_includes sheet, 'data-cart-sheet-mode={mode}'
    assert_includes sheet, "MODE_EXPANDED"
    assert_includes sheet, "MODE_PEEK"
    assert_includes sheet, "MODE_HIDDEN"
    %w[MODE_EXPANDED MODE_PEEK MODE_HIDDEN].each do |const|
      assert_includes thresholds, const
    end
  end

  test "programmatic mode via cartSheetMode store" do
    store = File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))

    assert_includes store, "export const cartSheetMode"
    assert_includes store, "MODE_PEEK"
    assert_includes store, "MODE_EXPANDED"
    assert_includes store, "MODE_HIDDEN"
  end

  test "S2a animation 300ms and cart sheet pinned to bottom" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    thresholds = File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))

    assert_includes thresholds, "SHEET_TRANSITION_MS = 300"
    assert_includes thresholds, "CART_SHEET_BOTTOM_REM = 0"
    assert_includes thresholds, "CART_SHEET_MAX_WIDTH_PX = 414"
    assert_includes sheet, "SHEET_TRANSITION_MS"
    assert_includes sheet, "CART_SHEET_BOTTOM_REM"
    assert_includes sheet, "CART_SHEET_MAX_WIDTH_PX"
    assert_includes sheet, "z-50"
    assert_match(/transition-\[height(?:,bottom)?\]/, sheet)
    assert_includes sheet, "transition-duration"
  end

  test "hidden mode shows product image chips not price-only chip" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    thresholds = File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))

    assert_includes sheet, 'data-testid="shop-cart-hidden-chips"'
    assert_includes sheet, 'data-testid="shop-cart-hidden-thumb"'
    assert_includes sheet, 'data-cart-layout="hidden-chips"'
    refute_includes sheet, ">Корзина</span>"
    assert_includes thresholds, 'CART_SHEET_BUILD = "prog32"'
    assert_match(/hidden:\s*24/, thresholds)
    assert_match(/expandedMulti:\s*56/, thresholds)
    assert_match(/peekMulti:\s*38/, thresholds)
  end

  test "peek and hidden show order total per S2a" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, "shop-cart-peek-total"
    assert_includes sheet, 'data-testid="shop-cart-hidden-total"'
    assert_includes sheet, "formatCartButtonTotal(total)"
  end

  test "CartSheet swipe handlers touch and pointer" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    store = File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))

    assert_includes sheet, "pointerdown"
    assert_includes sheet, "pointerup"
    assert_includes sheet, "pointercancel"
    assert_includes sheet, "$effect"
    assert_includes sheet, "touchstart"
    assert_includes sheet, "handleSheetGestureDelta"
    assert_includes sheet, 'data-testid="shop-cart-sheet-gesture-zone"'
    assert_includes store, "collapseFromSwipe"
    assert_includes store, "expandFromSwipe"
  end

  test "cart api returns expanded card payload fields" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 2, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      sess.get "/shop/api/cart", headers: shop_tenant_headers(@tenant.id), as: :json
      assert_equal 200, sess.response.status
      line = sess.response.parsed_body["items"].first
      assert line["product_name"].present?
      assert line["quantity"].to_i == 2
      assert line["unit_total"].to_f.positive?
      assert line.key?("selected_modifiers")
      assert sess.response.parsed_body["total"].to_f.positive?
    end
  end

  test "sheetHeightVh mirrors S2-канон viewport heights" do
    assert_equal 44, sheet_height_vh("expanded", 2)
    assert_equal 30, sheet_height_vh("peek", 2)
    assert_equal 28, sheet_height_vh("peek", 1)
    assert_equal 20, sheet_height_vh("hidden", 1)
  end

  private

  def sheet_height_vh(mode, item_count)
    case mode
    when "expanded" then item_count <= 1 ? 44 : 44
    when "peek" then item_count <= 1 ? 28 : 30
    when "hidden" then 20
    else 12
    end
  end
end
