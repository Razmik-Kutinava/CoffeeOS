# frozen_string_literal: true

require "test_helper"

class Shop::Api::OrdersControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)
    @customer = create_mobile_customer!(email: "orders-controller@example.com")
    @email = @customer.email
  end

  test "POST /shop/api/orders with client_order_uuid is idempotent" do
    post "/shop/api/cart/add",
      headers: shop_tenant_headers(@tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    uuid = SecureRandom.uuid
    params = shop_order_params(email: @email, name: "Dup User", payment_method: "card").merge(client_order_uuid: uuid)

    post "/shop/api/orders",
      headers: shop_tenant_headers(@tenant.id),
      params: params,
      as: :json
    assert_response :success
    first_id = response.parsed_body["order_id"]

    post "/shop/api/orders",
      headers: shop_tenant_headers(@tenant.id),
      params: params,
      as: :json
    assert_response :success
    assert_equal first_id, response.parsed_body["order_id"]
    assert_equal 1, Order.where(tenant_id: @tenant.id, source: :mobile, customer_id: @customer.id).count
    assert_equal uuid, Order.find(first_id).client_order_uuid
  end

  test "POST /shop/api/orders with client_order_uuid is idempotent without Rails.cache" do
    post "/shop/api/cart/add",
      headers: shop_tenant_headers(@tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    uuid = SecureRandom.uuid
    params = shop_order_params(email: @email, name: "Cache Free", payment_method: "card").merge(client_order_uuid: uuid)

    Rails.cache.clear

    post "/shop/api/orders",
      headers: shop_tenant_headers(@tenant.id),
      params: params,
      as: :json
    assert_response :success
    first_id = response.parsed_body["order_id"]

    Rails.cache.clear

    post "/shop/api/orders",
      headers: shop_tenant_headers(@tenant.id),
      params: params,
      as: :json
    assert_response :success
    assert_equal first_id, response.parsed_body["order_id"]
  end

  test "POST /shop/api/orders with payment_method cash returns 422 and creates nothing" do
    post "/shop/api/cart/add",
      headers: shop_tenant_headers(@tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    before_orders = Order.count
    before_payments = Payment.count

    post "/shop/api/orders",
      headers: shop_tenant_headers(@tenant.id),
      params: shop_order_params(email: @email, name: "Cash Guest", payment_method: "cash"),
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal Shop::PaymentConfig::CASH_ONLINE_ERROR, json["error"]
    assert_equal before_orders, Order.count
    assert_equal before_payments, Payment.count
  end

  test "POST /shop/api/orders creates order" do
    post "/shop/api/cart/add",
      headers: shop_tenant_headers(@tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    post "/shop/api/orders",
      headers: shop_tenant_headers(@tenant.id),
      params: shop_order_params(email: @email, name: "Test User", payment_method: "card"),
      as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["order_id"].present?
    assert_equal "accepted", json["status"]
    assert json["total"] == 200.0
  end

  test "POST /shop/api/orders without email returns error" do
    post "/shop/api/cart/add",
      headers: shop_tenant_headers(@tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    post "/shop/api/orders",
      headers: shop_tenant_headers(@tenant.id),
      params: { payment_method: "card" },
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"].to_s.downcase.include?("email")
  end

  test "GET /shop/api/orders/history returns orders" do
    get "/shop/api/orders/history",
      headers: shop_tenant_headers(@tenant.id)

    assert_response :success
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end

  test "GET /shop/api/orders/history?today=1 returns only todays orders" do
    post "/shop/api/cart/add",
      headers: shop_tenant_headers(@tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    post "/shop/api/orders",
      headers: shop_tenant_headers(@tenant.id),
      params: shop_order_params(email: @email, name: "Today User", payment_method: "card"),
      as: :json
    assert_response :success

    get "/shop/api/orders/history",
      headers: shop_tenant_headers(@tenant.id),
      params: { today: 1 }

    assert_response :success
    json = JSON.parse(response.body)
    assert json.length >= 1
    assert json.all? { |row| Time.zone.parse(row["created_at"]) >= Time.zone.today.beginning_of_day }
  end

  test "GET /shop/api/orders/:id returns order for session customer" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: @email, name: "Owner", payment_method: "card"),
        as: :json
      assert_equal 200, sess.response.status
      order_id = sess.response.parsed_body["order_id"]

      sess.get "/shop/api/orders/#{order_id}",
        headers: shop_tenant_headers(@tenant.id)
      assert_equal 200, sess.response.status
      body = sess.response.parsed_body
      assert_equal order_id, body["id"]
      assert body["order_number"].present?
      assert_equal true, body["payment_settled"]
      assert body["created_at"].present?
      assert_equal @tenant.name, body.dig("tenant", "name")
      assert body["items"].is_a?(Array)
      assert body["items"].first["product_name"].present?
    end
  end

  test "history is isolated per shop tenant for same email" do
    tenant_b = create_tenant!(name: "Shop B", slug: "shop-b-#{SecureRandom.hex(4)}")
    enable_product_for_tenant!(tenant: tenant_b, product: @product, price: 210)
    email = "isolated-#{SecureRandom.hex(4)}@example.com"

    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: email, session: sess)
      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: email, name: "A Guest", payment_method: "card"),
        as: :json
      order_a = sess.response.parsed_body["order_id"]

      sess.get "/shop/api/orders/history",
        headers: shop_tenant_headers(@tenant.id),
        params: { today: 1 }
      ids_a = sess.response.parsed_body.map { |r| r["id"] }
      assert_includes ids_a, order_a

      sess.get "/shop/api/orders/history",
        headers: shop_tenant_headers(tenant_b.id),
        params: { today: 1 }
      assert_empty sess.response.parsed_body

      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(tenant_b.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: tenant_b.id, email: email, session: sess)
      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(tenant_b.id),
        params: shop_order_params(email: email, name: "B Guest", payment_method: "card"),
        as: :json
      order_b = sess.response.parsed_body["order_id"]

      sess.get "/shop/api/orders/history",
        headers: shop_tenant_headers(tenant_b.id),
        params: { today: 1 }
      ids_b = sess.response.parsed_body.map { |r| r["id"] }
      assert_includes ids_b, order_b
      assert_not_includes ids_b, order_a
    end
  end

  test "GET /shop/api/orders/:id without session is unauthorized" do
    order_id = nil
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: @email, name: "Owner", payment_method: "card"),
        as: :json
      order_id = sess.response.parsed_body["order_id"]
    end

    open_session do |other|
      other.get "/shop/api/orders/#{order_id}",
        headers: shop_tenant_headers(@tenant.id)
      assert_equal 401, other.response.status
      assert_not_includes other.response.body, "order_number"
      assert_not_includes other.response.body, "items"
    end
  end

  test "GET /shop/api/orders/:id hides order from another guest on same tenant" do
    order_id = nil
    open_session do |sess_a|
      sess_a.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess_a)
      sess_a.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: @email, name: "Guest A", payment_method: "card"),
        as: :json
      assert_equal 200, sess_a.response.status
      order_id = sess_a.response.parsed_body["order_id"]
    end

    email_b = "guest-b-#{SecureRandom.hex(4)}@example.com"
    open_session do |sess_b|
      sess_b.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: email_b, session: sess_b)
      sess_b.get "/shop/api/orders/#{order_id}",
        headers: shop_tenant_headers(@tenant.id)
      assert_includes [ 401, 403, 404 ], sess_b.response.status
      body = sess_b.response.body.to_s
      assert_not_includes body, "order_number"
      refute_equal order_id, sess_b.response.parsed_body&.dig("id") if sess_b.response.content_type.to_s.include?("json")
    end
  end

  test "GET /shop/api/orders/:id reconnects guest via reconnect_token without prior session" do
    order_id = nil
    token = nil
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: @email, name: "Return Guest", payment_method: "card"),
        as: :json
      assert_equal 200, sess.response.status
      order_id = sess.response.parsed_body["order_id"]
      token = sess.response.parsed_body["reconnect_token"]
      assert token.present?
    end

    open_session do |lost|
      lost.get "/shop/api/orders/#{order_id}",
        headers: shop_tenant_headers(@tenant.id),
        params: { reconnect_token: token }
      assert_equal 200, lost.response.status
      assert_equal order_id, lost.response.parsed_body["id"]
    end
  end
end
