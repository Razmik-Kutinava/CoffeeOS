# frozen_string_literal: true

require "test_helper"

# TASK_116: GET /orders/history и GET /orders/:id по сети CODE:BLACK.
class Shop::Api::OrdersHistoryCodeBlackTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @org_a = create_organization!(name: "CB OrgA #{SecureRandom.hex(3)}")
    @org_b = create_organization!(name: "CB OrgB #{SecureRandom.hex(3)}")
    @point_a = create_tenant!(name: "Net A", slug: "net-a-#{SecureRandom.hex(3)}", organization: @org_a, code_black_member: true, city: "Казань", address: "ул. А, 1")
    @point_b = create_tenant!(name: "Net B", slug: "net-b-#{SecureRandom.hex(3)}", organization: @org_b, code_black_member: true, city: "Казань", address: "ул. Б, 2")
    @point_closed = create_tenant!(
      name: "Net Closed",
      slug: "net-c-#{SecureRandom.hex(3)}",
      organization: @org_a,
      code_black_member: true,
      status: "blocked",
      city: "Казань",
      address: "ул. Закрыта, 3"
    )
    @point_out = create_tenant!(name: "Out", slug: "out-#{SecureRandom.hex(3)}", organization: @org_a, code_black_member: false)
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @point_a, product: @product, price: 200)
    enable_product_for_tenant!(tenant: @point_b, product: @product, price: 210)
    enable_product_for_tenant!(tenant: @point_closed, product: @product, price: 220)
    enable_product_for_tenant!(tenant: @point_out, product: @product, price: 230)
    @customer = create_mobile_customer!(email: "cb-api-#{SecureRandom.hex(3)}@example.com")
    @other = create_mobile_customer!(email: "cb-api-o-#{SecureRandom.hex(3)}@example.com")
    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
  end

  teardown do
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
  end

  def headers(tenant)
    shop_tenant_headers(tenant.id)
  end

  def seed_order!(tenant:, customer:, created_at: Time.current)
    order = Order.create!(
      tenant_id: tenant.id,
      customer_id: customer.id,
      customer_name: "Guest",
      order_number: "API116-#{SecureRandom.hex(3)}",
      source: :mobile,
      status: :issued,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200,
      created_at: created_at
    )
    OrderItem.create!(
      order: order,
      product_id: @product.id,
      product_name: @product.name,
      quantity: 1,
      unit_price: 200,
      total_price: 200
    )
    order
  end

  def login!(session, tenant:)
    verify_shop_email!(tenant_id: tenant.id, email: @customer.email, session: session)
  end

  test "history across CODE:BLACK network returns tenant payload and closed mark" do
    oa = seed_order!(tenant: @point_a, customer: @customer, created_at: 3.hours.ago)
    ob = seed_order!(tenant: @point_b, customer: @customer, created_at: 2.hours.ago)
    oc = seed_order!(tenant: @point_closed, customer: @customer, created_at: 1.hour.ago)
    seed_order!(tenant: @point_out, customer: @customer)

    open_session do |sess|
      login!(sess, tenant: @point_a)
      sess.get "/shop/api/orders/history", headers: headers(@point_a), params: { page: 1, per_page: 20 }
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      ids = body.map { |r| r["id"] }
      assert_equal [ oc.id, ob.id, oa.id ], ids

      row_b = body.find { |r| r["id"] == ob.id }
      assert_equal @point_b.id, row_b.dig("tenant", "id")
      assert_equal @point_b.name, row_b.dig("tenant", "name")
      assert row_b.dig("tenant", "display_address").present?
      assert_equal false, row_b.dig("tenant", "closed")
      assert_equal "issued", row_b["status"]

      row_c = body.find { |r| r["id"] == oc.id }
      assert_equal true, row_c.dig("tenant", "closed")
    end
  end

  test "history pagination keeps descending created_at across points without duplicates" do
    orders = 3.times.map do |i|
      seed_order!(tenant: (i.even? ? @point_a : @point_b), customer: @customer, created_at: (3 - i).hours.ago)
    end

    open_session do |sess|
      login!(sess, tenant: @point_a)
      sess.get "/shop/api/orders/history", headers: headers(@point_a), params: { page: 1, per_page: 2 }
      page1 = sess.response.parsed_body.map { |r| r["id"] }
      sess.get "/shop/api/orders/history", headers: headers(@point_a), params: { page: 2, per_page: 2 }
      page2 = sess.response.parsed_body.map { |r| r["id"] }

      assert_equal 2, page1.size
      assert_equal 1, page2.size
      assert_empty(page1 & page2)
      assert_equal orders.map(&:id).reverse, page1 + page2
    end
  end

  test "customer_id or tenant_ids in params do not expand scope" do
    mine = seed_order!(tenant: @point_a, customer: @customer)
    foreign = seed_order!(tenant: @point_a, customer: @other)

    open_session do |sess|
      login!(sess, tenant: @point_a)
      sess.get "/shop/api/orders/history",
        headers: headers(@point_a),
        params: { customer_id: @other.id, tenant_ids: [ @point_out.id ] }
      ids = sess.response.parsed_body.map { |r| r["id"] }
      assert_includes ids, mine.id
      assert_not_includes ids, foreign.id
    end
  end

  test "GET show of other network point order succeeds without changing cart tenant" do
    order_b = seed_order!(tenant: @point_b, customer: @customer)

    open_session do |sess|
      login!(sess, tenant: @point_a)
      sess.post "/shop/api/cart/add",
        headers: headers(@point_a),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status
      cart_before = sess.response.parsed_body

      sess.get "/shop/api/orders/#{order_b.id}", headers: headers(@point_a)
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal order_b.id, body["id"]
      assert_equal @point_b.id, body.dig("tenant", "id")
      assert_equal @point_b.name, body.dig("tenant", "name")
      assert_equal false, body.dig("tenant", "closed")

      sess.get "/shop/api/cart", headers: headers(@point_a)
      assert_equal 200, sess.response.status
      cart_after = sess.response.parsed_body
      assert_equal cart_before["total"] || cart_before.dig("items")&.size,
                   cart_after["total"] || cart_after.dig("items")&.size
    end
  end

  test "GET show foreign or outside-network order returns 404" do
    foreign = seed_order!(tenant: @point_a, customer: @other)
    outside = seed_order!(tenant: @point_out, customer: @customer)

    open_session do |sess|
      login!(sess, tenant: @point_a)
      sess.get "/shop/api/orders/#{foreign.id}", headers: headers(@point_a)
      assert_equal 404, sess.response.status
      refute_includes sess.response.body, @other.email.to_s

      sess.get "/shop/api/orders/#{outside.id}", headers: headers(@point_a)
      assert_equal 404, sess.response.status
    end
  end

  test "outside network current point keeps single-tenant history" do
    seed_order!(tenant: @point_a, customer: @customer)
    out = seed_order!(tenant: @point_out, customer: @customer)

    open_session do |sess|
      login!(sess, tenant: @point_out)
      sess.get "/shop/api/orders/history", headers: headers(@point_out)
      ids = sess.response.parsed_body.map { |r| r["id"] }
      assert_equal [ out.id ], ids
    end
  end
end
