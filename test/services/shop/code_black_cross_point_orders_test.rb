# frozen_string_literal: true

require "test_helper"

# TASK_116: выборка истории/чека по сети CODE:BLACK (фильтры в коде, без shop_city_lookup).
class Shop::CodeBlackCrossPointOrdersTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @org_a = create_organization!(name: "Org A #{SecureRandom.hex(3)}")
    @org_b = create_organization!(name: "Org B #{SecureRandom.hex(3)}")
    @point_a = create_tenant!(name: "Point A", slug: "cb-a-#{SecureRandom.hex(3)}", organization: @org_a, code_black_member: true)
    @point_b = create_tenant!(name: "Point B", slug: "cb-b-#{SecureRandom.hex(3)}", organization: @org_b, code_black_member: true)
    @point_closed = create_tenant!(
      name: "Point Closed",
      slug: "cb-c-#{SecureRandom.hex(3)}",
      organization: @org_a,
      code_black_member: true,
      status: "suspended"
    )
    @point_out = create_tenant!(name: "Outside", slug: "out-#{SecureRandom.hex(3)}", organization: @org_a, code_black_member: false)
    @customer = create_mobile_customer!(email: "cb-hist-#{SecureRandom.hex(3)}@example.com")
    @other = create_mobile_customer!(email: "cb-other-#{SecureRandom.hex(3)}@example.com")
    @category = create_category!
    @product = create_product!(category: @category)
  end

  def make_order!(tenant:, customer:, created_at: Time.current)
    order = Order.create!(
      tenant_id: tenant.id,
      customer_id: customer.id,
      customer_name: "Guest",
      order_number: "T116-#{SecureRandom.hex(3)}",
      source: :mobile,
      status: :issued,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100,
      created_at: created_at
    )
    OrderItem.create!(
      order: order,
      product_id: @product.id,
      product_name: @product.name,
      quantity: 1,
      unit_price: 100,
      total_price: 100
    )
    order
  end

  def service(tenant:, customer_id:)
    Shop::CodeBlackCrossPointOrders.new(current_tenant: tenant, customer_id: customer_id)
  end

  test "network current → history includes orders from all network points incl. other org and closed" do
    oa = make_order!(tenant: @point_a, customer: @customer, created_at: 3.hours.ago)
    ob = make_order!(tenant: @point_b, customer: @customer, created_at: 2.hours.ago)
    oc = make_order!(tenant: @point_closed, customer: @customer, created_at: 1.hour.ago)
    make_order!(tenant: @point_out, customer: @customer)

    ids = service(tenant: @point_a, customer_id: @customer.id).history_scope.map(&:id)
    assert_equal [ oc.id, ob.id, oa.id ], ids
  end

  test "order outside network is excluded when current is in network" do
    make_order!(tenant: @point_out, customer: @customer)
    oa = make_order!(tenant: @point_a, customer: @customer)

    ids = service(tenant: @point_a, customer_id: @customer.id).history_scope.map(&:id)
    assert_equal [ oa.id ], ids
  end

  test "current outside network → only that point (Subtask 13)" do
    make_order!(tenant: @point_a, customer: @customer)
    out = make_order!(tenant: @point_out, customer: @customer)

    ids = service(tenant: @point_out, customer_id: @customer.id).history_scope.map(&:id)
    assert_equal [ out.id ], ids
  end

  test "other customer orders never appear" do
    make_order!(tenant: @point_a, customer: @other)
    mine = make_order!(tenant: @point_b, customer: @customer)

    ids = service(tenant: @point_a, customer_id: @customer.id).history_scope.map(&:id)
    assert_equal [ mine.id ], ids
  end

  test "blank customer_id → empty scope" do
    make_order!(tenant: @point_a, customer: @customer)
    assert_empty service(tenant: @point_a, customer_id: nil).history_scope.map(&:id)
    assert_empty service(tenant: @point_a, customer_id: "").history_scope.map(&:id)
  end

  test "find_order! returns own network order from another point" do
    order = make_order!(tenant: @point_b, customer: @customer)
    found = service(tenant: @point_a, customer_id: @customer.id).find_order!(order.id)
    assert_equal order.id, found.id
  end

  test "find_order! raises for foreign customer or outside network" do
    foreign = make_order!(tenant: @point_a, customer: @other)
    outside = make_order!(tenant: @point_out, customer: @customer)

    assert_raises(ActiveRecord::RecordNotFound) do
      service(tenant: @point_a, customer_id: @customer.id).find_order!(foreign.id)
    end
    assert_raises(ActiveRecord::RecordNotFound) do
      service(tenant: @point_a, customer_id: @customer.id).find_order!(outside.id)
    end
  end

  test "tenant_json includes id name display_address and closed flag" do
    payload = service(tenant: @point_a, customer_id: @customer.id).tenant_json(@point_closed)
    assert_equal @point_closed.id, payload[:id]
    assert_equal @point_closed.name, payload[:name]
    assert payload[:display_address].present?
    assert_equal true, payload[:closed]

    open_payload = service(tenant: @point_a, customer_id: @customer.id).tenant_json(@point_a)
    assert_equal false, open_payload[:closed]
  end

  test "source does not call shop_city_lookup" do
    path = Rails.root.join("app/services/shop/code_black_cross_point_orders.rb")
    src = File.read(path)
    refute_includes src, "shop_city_lookup"
    refute_includes src, "with_shop_city_lookup"
    refute_includes src, "CustomerTenantHistory"
  end
end
