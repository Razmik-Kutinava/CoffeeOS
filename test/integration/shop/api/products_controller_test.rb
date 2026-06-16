# frozen_string_literal: true

require "test_helper"

class Shop::Api::ProductsControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    @category = create_category!(name: "Кофе", slug: "shop-api-cat-#{SecureRandom.hex(3)}")
    @product = create_product!(category: @category, name: "Латте", slug: "shop-api-prod-#{SecureRandom.hex(3)}")
    @product.update!(description: "Из каталога УК", base_price: 250)
    @setting = enable_product_for_tenant!(tenant: @tenant, product: @product, price: 280)
    @group = ProductModifierGroup.create!(product: @product, name: "Размер", is_required: true, sort_order: 1)
    @option = ProductModifierOption.create!(group: @group, name: "L", price_delta: 50, sort_order: 1)
  end

  test "GET /shop/api/products returns tenant catalog with PTS price" do
    get "/shop/api/products", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success

    json = JSON.parse(response.body)
    row = json["data"].find { |p| p["id"] == @product.id }
    assert row
    assert_equal 280.0, row["price"]
    assert_equal @category.name, row.dig("category", "name")
  end

  test "GET /shop/api/products/:id returns card with modifier groups from UK catalog" do
    get "/shop/api/products/#{@product.id}", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @product.name, json["name"]
    assert_equal 280.0, json["price"]
    assert_equal 1, json["modifier_groups"].size
    mod = json["modifier_groups"].first
    assert_equal "Размер", mod["name"]
    assert_equal "required", mod["modifier_type"]
    assert_equal @option.id, mod["modifiers"].first["id"]
    assert_equal 50.0, mod["modifiers"].first["price_change"]
  end

  test "GET /shop/api/products/:id for disabled PTS returns 404" do
    @setting.update!(is_enabled: false)
    get "/shop/api/products/#{@product.id}", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :not_found
  end

  test "GET /shop/api/products/:id deduplicates modifier groups with same name" do
    dup_group = ProductModifierGroup.create!(product: @product, name: "Размер", is_required: true, sort_order: 2)
    ProductModifierOption.create!(group: dup_group, name: "XL", price_delta: 70, sort_order: 1)

    get "/shop/api/products/#{@product.id}", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["modifier_groups"].size
    names = json["modifier_groups"].first["modifiers"].map { |m| m["name"] }
    assert_includes names, "L"
    assert_includes names, "XL"
  end
end
