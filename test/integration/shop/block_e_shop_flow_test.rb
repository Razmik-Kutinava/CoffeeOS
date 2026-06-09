# frozen_string_literal: true

require "test_helper"

# Веха 1 / блок E: полный shop API-флоу (меню → корзина+модификаторы → mock оплата → история за сегодня).
class BlockEShopFlowTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "be-shop-#{SecureRandom.hex(3)}")
    @category = create_category!(slug: "be-cat-#{SecureRandom.hex(3)}", name: "Кофе")
    @product = create_product!(category: @category, slug: "be-prod-#{SecureRandom.hex(3)}", name: "Капучино")
    @product.update!(base_price: 200)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 250)

    @group = ProductModifierGroup.create!(product: @product, name: "Размер", is_required: true, sort_order: 1)
    @option = ProductModifierOption.create!(group: @group, name: "L", price_delta: 40, sort_order: 1)

    @email = "block-e-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    @headers = { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  test "menu categories return data envelope with product tiles" do
    get "/shop/api/categories", headers: @headers
    assert_response :success

    body = response.parsed_body
    assert body["data"].is_a?(Array)
    row = body["data"].flat_map { |c| c["products"] }.find { |p| p["id"] == @product.id }
    assert row
    assert_equal 250.0, row["price"]
    assert_equal "Капучино", row["name"]
  end

  test "cart add remove and modifiers one level" do
    mods = [{ id: @option.id, name: "L", price: 40.0 }]

    post "/shop/api/cart/add",
      headers: @headers,
      params: { product_id: @product.id, quantity: 1, selected_modifiers: mods },
      as: :json
    assert_response :success
    assert_equal 290.0, response.parsed_body["total"]

    get "/shop/api/cart", headers: @headers
    assert_response :success
    items = response.parsed_body["items"]
    assert_equal 1, items.size
    assert_equal 1, items.first["selected_modifiers"].size
    assert_equal "L", items.first["selected_modifiers"].first["name"]

    patch "/shop/api/cart/items/0",
      headers: @headers,
      params: { delta: 1 },
      as: :json
    assert_response :success
    assert_equal 580.0, response.parsed_body["total"]

    delete "/shop/api/cart/items/0", headers: @headers, as: :json
    assert_response :success
    assert_equal 0, response.parsed_body["items"].size
    assert_equal 0.0, response.parsed_body["total"]
  end

  test "mock payment creates accepted order" do
    post "/shop/api/cart/add",
      headers: @headers,
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    post "/shop/api/orders",
      headers: @headers,
      params: shop_order_params(email: @email, name: "Block E", payment_method: "mock"),
      as: :json
    assert_response :success

    body = response.parsed_body
    assert body["order_id"].present?
    assert_equal "accepted", body["status"]
    assert_equal 250.0, body["total"]

    order = Order.find(body["order_id"])
    assert_equal "mobile", order.source
    assert_equal "succeeded", order.payments.first.status
  end

  test "history today excludes older orders" do
    post "/shop/api/cart/add",
      headers: @headers,
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    post "/shop/api/orders",
      headers: @headers,
      params: shop_order_params(email: @email, name: "Today", payment_method: "mock"),
      as: :json
    assert_response :success
    today_id = response.parsed_body["order_id"]

    # второй заказ — «вчера» через прямое обновление (тот же customer session)
    post "/shop/api/cart/add",
      headers: @headers,
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    post "/shop/api/orders",
      headers: @headers,
      params: shop_order_params(email: @email, name: "Yesterday", payment_method: "mock"),
      as: :json
    assert_response :success
    old_id = response.parsed_body["order_id"]
    Order.where(id: old_id).update_all(created_at: 2.days.ago)

    get "/shop/api/orders/history", headers: @headers, params: { today: 1 }
    assert_response :success
    ids = response.parsed_body.map { |r| r["id"] }
    assert_includes ids, today_id
    assert_not_includes ids, old_id
  end

  test "shop home route is registered" do
    assert_routing(
      { path: "/shop", method: :get },
      { controller: "shop/pages", action: "home" }
    )
  end
end
