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
    assert json["meta"]["per_page"] == 1
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
end
