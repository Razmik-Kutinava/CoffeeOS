# frozen_string_literal: true

require "test_helper"

# Shop API: явная привязка к tenant + PTS — точка A не получает цены точки B.
class Shop::Api::TenantIsolationTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @category = create_category!
    @product = create_product!(category: @category, name: "Изоляция Shop")
    @tenant_a = create_tenant!(slug: "shop-iso-a-#{SecureRandom.hex(3)}")
    @tenant_b = create_tenant!(slug: "shop-iso-b-#{SecureRandom.hex(3)}")
    enable_product_for_tenant!(tenant: @tenant_a, product: @product, price: 111)
    enable_product_for_tenant!(tenant: @tenant_b, product: @product, price: 222)
  end

  test "shop menu price follows X-Shop-Tenant not other point" do
    get "/shop/api/products/#{@product.id}", headers: { "X-Shop-Tenant" => @tenant_a.id.to_s }
    assert_response :success
    assert_equal 111.0, response.parsed_body["price"]

    get "/shop/api/products/#{@product.id}", headers: { "X-Shop-Tenant" => @tenant_b.id.to_s }
    assert_response :success
    assert_equal 222.0, response.parsed_body["price"]
  end

  test "shop categories for tenant a do not expose tenant b pts price" do
    get "/shop/api/categories", headers: { "X-Shop-Tenant" => @tenant_a.id.to_s }
    assert_response :success

    products = response.parsed_body["data"].flat_map { |c| c["products"] }
    row = products.find { |p| p["id"] == @product.id }
    assert row
    assert_equal 111.0, row["price"]
  end
end
