# frozen_string_literal: true

require "test_helper"

# #36 A1/A2 — расширенный GET /shop/api/orders/active (чек: items, mods, totals) [TDD RED]
class Shop::Api::ActiveOrdersReceiptTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!(name: "Point A", address: "Lenina 1", city: "Kazan")
    @customer = create_mobile_customer!(email: "active-receipt-#{SecureRandom.hex(3)}@example.com")
    @email = @customer.email
    @category = create_category!
    @product = create_product!(category: @category, name: "Капучино")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 250)

    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "202607-36a1",
      source: :mobile,
      status: :preparing,
      total_amount: 280,
      discount_amount: 30,
      final_amount: 250
    )
    OrderItem.create!(
      order: @order,
      product_id: @product.id,
      product_name: "Капучино",
      quantity: 1,
      unit_price: 280,
      total_price: 280,
      modifier_options: {
        "selected_modifiers" => [
          { "id" => SecureRandom.uuid, "name" => "Сироп ваниль", "price" => 30 }
        ]
      }
    )
  end

  test "#36 A1 GET orders/active includes created_at sales_point items totals [TDD]" do
    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    get "/shop/api/orders/active", headers: shop_tenant_headers(@tenant.id), as: :json

    assert_response :success
    orders = response.parsed_body["orders"]
    row = orders.find { |o| (o["id"] || o["order_id"]) == @order.id }
    assert row, "active order missing from response"

    # #35 keys preserved
    assert_equal "preparing", row["status"]
    assert_equal "202607-36a1", row["order_number"]
    assert row.key?("payment_settled")

    # #36 A1
    assert row["created_at"].present?, "expected created_at"
    assert_kind_of Hash, row["sales_point"]
    assert_equal "Point A", row["sales_point"]["name"]
    assert_equal 280.0, row["subtotal"].to_f
    assert_equal 30.0, row["discount"].to_f
    assert_equal 250.0, row["total_amount"].to_f

    assert_kind_of Array, row["items"]
    assert_equal 1, row["items"].size
    item = row["items"].first
    assert_equal @product.id, item["product_id"]
    assert_equal "Капучино", item["name"]
    assert_equal 1, item["quantity"]
    assert_equal 280.0, item["price"].to_f
    assert_kind_of Array, item["modifiers"]
  end

  test "#36 A2 GET orders/active item modifiers have name and price [TDD]" do
    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    get "/shop/api/orders/active", headers: shop_tenant_headers(@tenant.id), as: :json

    assert_response :success
    row = response.parsed_body["orders"].find { |o| (o["id"] || o["order_id"]) == @order.id }
    assert_kind_of Array, row["items"], "expected items array"
    assert_operator row["items"].size, :>=, 1
    mods = row["items"].first["modifiers"]
    assert_kind_of Array, mods
    assert_equal 1, mods.size
    assert_equal "Сироп ваниль", mods.first["name"]
    assert_equal 30.0, mods.first["price"].to_f
  end

  test "#36 A2 item without modifiers returns empty modifiers array [TDD]" do
    plain = create_product!(category: @category, name: "Эспрессо")
    enable_product_for_tenant!(tenant: @tenant, product: plain, price: 150)
    bare = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "202607-36a2",
      source: :mobile,
      status: :accepted,
      total_amount: 150,
      discount_amount: 0,
      final_amount: 150
    )
    OrderItem.create!(
      order: bare,
      product_id: plain.id,
      product_name: "Эспрессо",
      quantity: 1,
      unit_price: 150,
      total_price: 150,
      modifier_options: { "selected_modifiers" => [] }
    )

    verify_shop_email!(tenant_id: @tenant.id, email: @email)
    get "/shop/api/orders/active", headers: shop_tenant_headers(@tenant.id), as: :json

    assert_response :success
    row = response.parsed_body["orders"].find { |o| (o["id"] || o["order_id"]) == bare.id }
    assert_kind_of Array, row["items"], "expected items array"
    assert_equal [], row["items"].first["modifiers"]
  end

  test "#36 A1 zero discount is exposed on active payload [TDD]" do
    plain = create_product!(category: @category, name: "Американо")
    enable_product_for_tenant!(tenant: @tenant, product: plain, price: 120)
    zero = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "202607-36zero",
      source: :mobile,
      status: :ready,
      total_amount: 120,
      discount_amount: 0,
      final_amount: 120
    )
    OrderItem.create!(
      order: zero,
      product_id: plain.id,
      product_name: "Американо",
      quantity: 1,
      unit_price: 120,
      total_price: 120,
      modifier_options: {}
    )

    verify_shop_email!(tenant_id: @tenant.id, email: @email)
    get "/shop/api/orders/active", headers: shop_tenant_headers(@tenant.id), as: :json

    assert_response :success
    row = response.parsed_body["orders"].find { |o| (o["id"] || o["order_id"]) == zero.id }
    assert row.key?("discount"), "expected discount key"
    assert_equal 0.0, row["discount"].to_f
    assert_equal 120.0, row["total_amount"].to_f
    assert_kind_of Array, row["items"]
  end
end
