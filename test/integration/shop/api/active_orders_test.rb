# frozen_string_literal: true

require "test_helper"

# #35 A3 — GET /shop/api/orders/active для реконнекта sticky-шторки [TDD RED]
class Shop::Api::ActiveOrdersTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(email: "active-orders-#{SecureRandom.hex(3)}@example.com")
    @email = @customer.email

    @active = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Active",
      order_number: "202607-3503a",
      source: :mobile,
      status: :preparing,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    @ready = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Ready",
      order_number: "202607-3503b",
      source: :mobile,
      status: :ready,
      total_amount: 120,
      discount_amount: 0,
      final_amount: 120
    )
    @issued = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Issued",
      order_number: "202607-3503c",
      source: :mobile,
      status: :issued,
      total_amount: 90,
      discount_amount: 0,
      final_amount: 90
    )
  end

  test "#35 GET orders/active returns accepted preparing only (no ready)" do
    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    get "/shop/api/orders/active", headers: shop_tenant_headers(@tenant.id), as: :json

    assert_response :success
    body = response.parsed_body
    orders = body.is_a?(Array) ? body : body["orders"]
    assert_kind_of Array, orders
    ids = orders.map { |o| o["id"] || o["order_id"] }
    assert_includes ids, @active.id
    assert_not_includes ids, @ready.id
    assert_not_includes ids, @issued.id

    preparing = orders.find { |o| (o["id"] || o["order_id"]) == @active.id }
    assert_equal "preparing", preparing["status"]
    assert preparing.key?("order_number")
    assert_equal false, preparing["can_cancel"]
  end

  test "#41 GET orders/active includes can_cancel for accepted guest orders" do
    accepted = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Accepted",
      order_number: "202608-4101",
      source: :mobile,
      status: :accepted,
      total_amount: 179,
      discount_amount: 0,
      final_amount: 179
    )
    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    get "/shop/api/orders/active", headers: shop_tenant_headers(@tenant.id), as: :json

    assert_response :success
    orders = response.parsed_body["orders"]
    row = orders.find { |o| o["id"] == accepted.id }
    assert_equal true, row["can_cancel"]
    assert_equal "accepted", row["status"]
  end

  test "#35 GET orders/active without session returns empty or unauthorized" do
    get "/shop/api/orders/active", headers: shop_tenant_headers(@tenant.id), as: :json

    assert_includes [200, 401], response.status
    if response.status == 200
      body = response.parsed_body
      orders = body.is_a?(Array) ? body : body["orders"]
      assert_equal [], orders
    end
  end

  test "#42 GET orders/active excludes stale accepted older than 24h" do
    stale = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Stale June",
      order_number: "202606-0259",
      source: :mobile,
      status: :accepted,
      total_amount: 3,
      discount_amount: 0,
      final_amount: 3,
      created_at: 40.days.ago,
      updated_at: 40.days.ago
    )
    fresh = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Fresh Today",
      order_number: "202608-4201",
      source: :mobile,
      status: :accepted,
      total_amount: 179,
      discount_amount: 0,
      final_amount: 179
    )
    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    get "/shop/api/orders/active", headers: shop_tenant_headers(@tenant.id), as: :json

    assert_response :success
    ids = response.parsed_body["orders"].map { |o| o["id"] }
    assert_includes ids, fresh.id
    assert_not_includes ids, stale.id
  end
end
