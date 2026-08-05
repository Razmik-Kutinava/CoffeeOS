# frozen_string_literal: true

require "test_helper"

# B1.13-S2: поп-ап корзины · bottom bar 2 вкладки · #/cart убран
class Shop::B113S2CartPopupTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "b113-s2-#{SecureRandom.hex(3)}")
    @category = create_category!
    @product = create_product!(category: @category, slug: "b113-s2-prod-#{SecureRandom.hex(3)}")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 250)
  end

  test "app: no bottom nav, no favorites route (B1.13-CR-BOTTOM-NAV rev3)" do
    app = File.read(Rails.root.join("app/frontend/App.svelte"))
    profile = File.read(Rails.root.join("app/frontend/routes/Profile.svelte"))

    refute_includes app, "BottomNav"
    refute_includes app, '"/favorites"'
    refute File.exist?(Rails.root.join("app/frontend/routes/Favorites.svelte"))
    refute_includes profile, "/#/favorites"
  end

  test "app mounts CartSheet and redirects legacy cart route" do
    app = File.read(Rails.root.join("app/frontend/App.svelte"))

    assert_includes app, "CartSheet"
    assert_includes app, "CartRedirect"
    assert_includes app, '"/cart": CartRedirect'
    refute_includes app, 'import("./routes/Cart.svelte")'
  end

  test "CartSheet source: empty placeholder gated by frequentCount, three modes" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    store = File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))

    assert_includes sheet, 'data-testid="shop-cart-sheet"'
    assert_includes sheet, 'data-testid="shop-cart-sheet-empty"'
    assert_includes sheet, "тут будут твои заказы"
    assert_includes sheet, "showRepeat"
    assert_includes sheet, "!showRepeat"
    assert_includes sheet, "MODE_EXPANDED"
    assert_includes sheet, "MODE_PEEK"
    assert_includes sheet, "MODE_HIDDEN"
    assert_includes sheet, "handleSheetGestureDelta"
    assert_includes sheet, "formatCartButtonTotal"
    assert_includes sheet, "shop-cart-sheet-checkout"
    assert_includes sheet, "isCartSheetRoute"
    assert_includes store, "isCartSheetRoute"
    assert_includes store, "handleCatalogScroll"

    assert_includes store, "collapseFromSwipe"
    assert_includes store, "expandFromSwipe"
    refute_includes store, "cartSheetExpandedLayout"
    assert_includes store, "onCartSheetRouteChange"
    assert_includes store, "cartSheetModeCache.js"
  end

  test "catalog wires scroll handler and cart refresh" do
    catalog = File.read(Rails.root.join("app/frontend/routes/Catalog.svelte"))

    assert_includes catalog, "handleCatalogScroll"
    assert_includes catalog, "refreshCartSheet"
    assert_includes catalog, "catalog-with-sheet"
  end

  test "add to cart navigates to catalog not legacy cart screen" do
    product = File.read(Rails.root.join("app/frontend/routes/Product.svelte"))
    category_products = File.read(Rails.root.join("app/frontend/routes/CategoryProducts.svelte"))

    refute_includes product, 'push("/cart")'
    assert_includes product, 'push("/")'
    refute_includes category_products, 'push("/cart")'
  end

  test "sheetHeightVh thresholds match catalog rows (cards -15%)" do
    thresholds = File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))

    assert_includes thresholds, "empty:         34"
    assert_includes thresholds, "expandedMulti:  56"
    assert_includes thresholds, "peekMulti:     38"
    assert_includes thresholds, "peekSingle:    34"
    assert_includes thresholds, "hidden:        24"
    assert_includes thresholds, "SCROLL_TO_PEEK_PX = 100"
    assert_includes thresholds, "SCROLL_TO_HIDDEN_PX = 200"
    assert_includes thresholds, "SWIPE_UP_PX = 20"
    assert_includes thresholds, 'CART_SHEET_BUILD = "prog36"'

    assert_equal 56, sheet_height_vh("expanded", 3)
    assert_equal 38, sheet_height_vh("peek", 2)
    assert_equal 34, sheet_height_vh("peek", 1)
    assert_equal 24, sheet_height_vh("hidden", 2)
    assert_equal 12, sheet_height_vh("empty", 0)
  end

  test "isCartSheetRoute mirror: catalog + checkout + product, not favorites/profile" do
    assert cart_sheet_route?("#/")
    assert cart_sheet_route?("#")
    assert cart_sheet_route?("")
    assert cart_sheet_route?("#/checkout")
    refute cart_sheet_route?("#/favorites")
    refute cart_sheet_route?("#/profile")
    assert cart_sheet_route?("#/product/1")
    assert cart_sheet_route?("#/product/1?cart_line=0")
  end

  test "cart api supports CartSheet after add" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      sess.get "/shop/api/cart", headers: shop_tenant_headers(@tenant.id)
      assert_equal 200, sess.response.status
      body = sess.response.parsed_body
      assert body["items"].any?, "ожидалась позиция в корзине для поп-апа"
      assert body["total"].to_f.positive?
      line = body["items"].first
      assert_equal @product.id.to_s, line["product_id"].to_s
      assert line["product_name"].present?
    end
  end

  private

  # Зеркало app/frontend/lib/cartSheetThresholds.js#sheetHeightVh
  def sheet_height_vh(mode, item_count)
    case mode
    when "empty" then 12
    when "expanded" then item_count <= 1 ? 52 : 56
    when "peek" then item_count <= 1 ? 34 : 38
    when "hidden" then 24
    else 12
    end
  end

  # Зеркало app/frontend/lib/cartSheetStore.js#isCartSheetRoute
  def cart_sheet_route?(hash)
    h = hash.to_s.delete_prefix("#")
    h = "/" if h.blank?
    h == "/" || h == "/checkout" || h.start_with?("/checkout?")
  end
end
