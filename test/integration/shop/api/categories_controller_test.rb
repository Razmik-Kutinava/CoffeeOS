# frozen_string_literal: true

require "test_helper"

class Shop::Api::CategoriesControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 150)
  end

  test "GET /shop/api/categories returns categories with products" do
    get "/shop/api/categories", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert json["meta"]["page"] == 1
    assert json["meta"]["per_page"] == 50
  end

  test "GET /shop/api/categories returns all categories by default" do
    cat2 = create_category!(name: "Вторая", slug: "cat-two-#{SecureRandom.hex(2)}")
    p2 = create_product!(category: cat2, name: "Tea", slug: "tea-#{SecureRandom.hex(2)}")
    enable_product_for_tenant!(tenant: @tenant, product: p2, price: 99)

    get "/shop/api/categories", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    json = JSON.parse(response.body)
    names = json["data"].map { |c| c["name"] }
    assert_includes names, cat2.name
    assert_operator json["data"].size, :>=, 2
  end

  test "GET /shop/api/categories with pagination" do
    get "/shop/api/categories?page=1&per_page=10", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["meta"]["page"] == 1
    assert json["meta"]["per_page"] == 10
  end

  test "GET /shop/api/categories without tenant resolves through fallback tenant" do
    get "/shop/api/categories"
    assert_response :success
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
  end

  # #65 linkage: query tenant_id (как во внешней ссылке TG/IG), не только X-Shop-Tenant
  test "GET /shop/api/categories?tenant_id= uses query tenant without header" do
    get "/shop/api/categories", params: { tenant_id: @tenant.id }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
  end

  test "GET /shop/api/categories?tenant_id= unknown returns 404 not fallback" do
    get "/shop/api/categories", params: { tenant_id: "00000000-0000-0000-0000-000000000099" }
    assert_response :not_found
    json = JSON.parse(response.body)
    assert_equal "Точка не найдена", json["error"]
  end

  test "GET /shop/api/categories?tenant_id= blank returns 422 not silent fallback" do
    get "/shop/api/categories", params: { tenant_id: "" }
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_match(/tenant_id|точка/i, json["error"])
  end
end
