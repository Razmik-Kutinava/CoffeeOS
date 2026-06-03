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
    assert_equal "accepted", json["status"]
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

  test "GET /shop/api/orders/history?today=1 returns only todays orders" do
    post "/shop/api/cart/add",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    post "/shop/api/orders",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { phone: @customer.phone, name: "Today User", payment_method: "mock" },
      as: :json
    assert_response :success

    get "/shop/api/orders/history",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { today: 1 }

    assert_response :success
    json = JSON.parse(response.body)
    assert json.length >= 1
    assert json.all? { |row| Time.zone.parse(row["created_at"]) >= Time.zone.today.beginning_of_day }
  end

  test "GET /shop/api/orders/:id returns order for session customer" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      sess.post "/shop/api/orders",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: { phone: @customer.phone, name: "Owner", payment_method: "cash" },
        as: :json
      assert_equal 200, sess.response.status
      order_id = sess.response.parsed_body["order_id"]

      sess.get "/shop/api/orders/#{order_id}",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s }
      assert_equal 200, sess.response.status
      assert_equal order_id, sess.response.parsed_body["id"]
    end
  end

  test "history is isolated per shop tenant for same phone" do
    tenant_b = create_tenant!(name: "Shop B", slug: "shop-b-#{SecureRandom.hex(4)}")
    enable_product_for_tenant!(tenant: tenant_b, product: @product, price: 210)
    phone = "+7999#{SecureRandom.random_number(10**7).to_s.rjust(7, '0')}"

    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      sess.post "/shop/api/orders",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: { phone: phone, name: "A Guest", payment_method: "cash" },
        as: :json
      order_a = sess.response.parsed_body["order_id"]

      sess.get "/shop/api/orders/history",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: { today: 1 }
      ids_a = sess.response.parsed_body.map { |r| r["id"] }
      assert_includes ids_a, order_a

      sess.get "/shop/api/orders/history",
        headers: { "X-Shop-Tenant" => tenant_b.id.to_s },
        params: { today: 1 }
      assert_empty sess.response.parsed_body

      sess.post "/shop/api/cart/add",
        headers: { "X-Shop-Tenant" => tenant_b.id.to_s },
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      sess.post "/shop/api/orders",
        headers: { "X-Shop-Tenant" => tenant_b.id.to_s },
        params: { phone: phone, name: "B Guest", payment_method: "cash" },
        as: :json
      order_b = sess.response.parsed_body["order_id"]

      sess.get "/shop/api/orders/history",
        headers: { "X-Shop-Tenant" => tenant_b.id.to_s },
        params: { today: 1 }
      ids_b = sess.response.parsed_body.map { |r| r["id"] }
      assert_includes ids_b, order_b
      assert_not_includes ids_b, order_a
    end
  end

  test "GET /shop/api/orders/:id hides order from another session" do
    order_id = nil
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      sess.post "/shop/api/orders",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: { phone: @customer.phone, name: "Owner", payment_method: "cash" },
        as: :json
      order_id = sess.response.parsed_body["order_id"]
    end

    open_session do |other|
      other.get "/shop/api/orders/#{order_id}",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s }
      assert_equal 404, other.response.status
    end
  end
end

