# frozen_string_literal: true

require "test_helper"

class Shop::Api::OrdersControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)
    @customer = create_mobile_customer!
  end

  test "POST /shop/api/orders creates order" do
    post "/shop/api/cart/add",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    post "/shop/api/orders",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: {
        phone: @customer.phone,
        name: "Test User",
        payment_method: "cash"
      },
      as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["order_id"].present?
    assert json["total"] == 200.0
  end

  test "POST /shop/api/orders without phone returns error" do
    post "/shop/api/cart/add",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    post "/shop/api/orders",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { payment_method: "cash" },
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"].to_s.downcase.include?("телефон")
  end

  test "GET /shop/api/orders/history returns orders" do
    get "/shop/api/orders/history",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s }

    assert_response :success
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end
end
