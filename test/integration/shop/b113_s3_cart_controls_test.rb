# frozen_string_literal: true

require "test_helper"

# B1.13-S3 — управление товарами в поп-апе корзины (+/−/Удалить/+цена).
class Shop::B113S3CartControlsTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "b113-s3-#{SecureRandom.hex(3)}")
    @category = create_category!
    @product = create_product!(category: @category, slug: "b113-s3-prod-#{SecureRandom.hex(3)}")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 300)
  end

  test "CartSheet S3 controls testids and peek without delete button" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-peek-minus"'
    assert_includes sheet, 'data-testid="shop-cart-peek-plus"'
    assert_includes sheet, 'data-testid="shop-cart-expanded-delete"'
    assert_includes sheet, 'data-testid="shop-cart-expanded-plus"'
    assert_includes sheet, "atMaxQty"
    assert_includes sheet, "MAX_ITEM_QUANTITY"
    refute_includes sheet, 'data-testid="shop-cart-peek-delete"'
  end

  test "PATCH delta +1 and -1 updates quantity and total" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      total1 = sess.response.parsed_body["total"].to_f

      sess.patch "/shop/api/cart/items/0",
        headers: shop_tenant_headers(@tenant.id),
        params: { delta: 1 },
        as: :json
      assert_equal 200, sess.response.status
      body = sess.response.parsed_body
      assert_equal 2, body["items"].first["quantity"]
      assert_equal total1 * 2, body["total"].to_f

      sess.patch "/shop/api/cart/items/0",
        headers: shop_tenant_headers(@tenant.id),
        params: { delta: -1 },
        as: :json
      assert_equal 200, sess.response.status
      body = sess.response.parsed_body
      assert_equal 1, body["items"].first["quantity"]
      assert_equal total1, body["total"].to_f
    end
  end

  test "PATCH delta -1 at qty 1 removes line and empties cart" do
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
      assert_equal 200, sess.response.status
      body = sess.response.parsed_body
      assert_empty body["items"]
      assert_equal 0, body["total"].to_f
    end
  end

  test "DELETE removes line from cart" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 2, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      sess.delete "/shop/api/cart/items/0", headers: shop_tenant_headers(@tenant.id)
      assert_equal 200, sess.response.status
      assert_empty sess.response.parsed_body["items"]
    end
  end

  test "checkout button routes to checkout hash in CartSheet" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-sheet-checkout"'
    assert_includes sheet, 'push("/checkout")'
  end
end
