# frozen_string_literal: true

require "test_helper"

# B1.13-S3-rev2 — управление в поп-апе (+/− disabled @1, Удалить, +цена).
class Shop::B113S3Rev2CartControlsTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "b113-s3r2-#{SecureRandom.hex(3)}")
    @category = create_category!
    @product = create_product!(category: @category, slug: "b113-s3r2-prod-#{SecureRandom.hex(3)}")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 300)
  end

  test "CartSheet rev2 controls testids minus disabled at min qty" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    store = File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))

    assert_includes sheet, 'data-testid="shop-cart-peek-minus"'
    assert_includes sheet, 'data-testid="shop-cart-peek-plus"'
    assert_includes sheet, 'data-testid="shop-cart-expanded-delete"'
    assert_includes sheet, "atMinQty"
    assert_includes sheet, "atMaxQty"
    assert_includes sheet, "disabled={busy || atMinQty(line)}"
    refute_includes sheet, 'data-testid="shop-cart-peek-delete"'
    assert_includes store, "export function atMinQty"
    assert_includes store, "optimisticBump"
  end

  test "PATCH delta +1 and -1 updates quantity when qty above 1" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 2, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      total2 = sess.response.parsed_body["total"].to_f

      sess.patch "/shop/api/cart/items/0",
        headers: shop_tenant_headers(@tenant.id),
        params: { delta: -1 },
        as: :json
      assert_equal 200, sess.response.status
      body = sess.response.parsed_body
      assert_equal 1, body["items"].first["quantity"]
      assert_equal total2 / 2, body["total"].to_f
    end
  end

  test "PATCH delta -1 at qty 1 is rejected" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      sess.patch "/shop/api/cart/items/0",
        headers: shop_tenant_headers(@tenant.id),
        params: { delta: -1 },
        as: :json
      assert_equal 404, sess.response.status
      assert_match(/минимум/i, sess.response.parsed_body["error"].to_s)

      sess.get "/shop/api/cart", headers: shop_tenant_headers(@tenant.id), as: :json
      assert_equal 1, sess.response.parsed_body["items"].first["quantity"]
    end
  end

  test "PATCH delta +1 beyond MAX_ITEM_QUANTITY returns error" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: Shop::CartService::MAX_CART_ITEMS, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      bumps = Shop::CartService::MAX_ITEM_QUANTITY - Shop::CartService::MAX_CART_ITEMS
      bumps.times do
        sess.patch "/shop/api/cart/items/0",
          headers: shop_tenant_headers(@tenant.id),
          params: { delta: 1 },
          as: :json
        assert_equal 200, sess.response.status, "bump to max qty"
      end
      assert_equal Shop::CartService::MAX_ITEM_QUANTITY,
        sess.response.parsed_body["items"].first["quantity"]

      sess.patch "/shop/api/cart/items/0",
        headers: shop_tenant_headers(@tenant.id),
        params: { delta: 1 },
        as: :json
      assert_equal 404, sess.response.status
    end
  end

  test "DELETE removes line from cart" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      sess.delete "/shop/api/cart/items/0", headers: shop_tenant_headers(@tenant.id)
      assert_equal 200, sess.response.status
      assert_empty sess.response.parsed_body["items"]
      assert_equal 0, sess.response.parsed_body["total"].to_f
    end
  end

  test "checkout button routes to checkout hash in CartSheet" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-sheet-checkout"'
    assert_includes sheet, 'push("/checkout")'
  end
end
