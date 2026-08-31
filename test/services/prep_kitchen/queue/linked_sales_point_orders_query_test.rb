# frozen_string_literal: true

require "test_helper"

class PrepKitchen::Queue::LinkedSalesPointOrdersQueryTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @org = Organization.create!(name: "Queue Org", slug: "q-org-#{SecureRandom.hex(4)}")
    @kitchen = create_prep_kitchen_tenant!(organization: @org)
    @point_a = create_tenant!(name: "Queue Point A", slug: "q-a-#{SecureRandom.hex(4)}", organization: @org)
    @point_b = create_tenant!(name: "Queue Point B", slug: "q-b-#{SecureRandom.hex(4)}", organization: @org)
    @manager = create_user!(tenant: @kitchen, role_codes: %w[prep_kitchen_manager])

    category = create_category!
    @product = create_product!(category: category, name: "Prep Queue Latte")
    enable_product_for_tenant!(tenant: @point_a, product: @product, price: 199)

    PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @kitchen, sales_point_tenant: @point_a)

    @linked_order = create_accepted_order!(
      tenant: @point_a,
      product: @product,
      order_number: "PK-LINK-001"
    )
    @unlinked_order = create_accepted_order!(
      tenant: @point_b,
      product: @product,
      order_number: "PK-UNLINK-002"
    )
  end

  test "returns orders only from linked sales points" do
    orders = PrepKitchen::Queue::LinkedSalesPointOrdersQuery.call(
      prep_kitchen_tenant_id: @kitchen.id,
      from: 3.hours.ago,
      to: 1.hour.from_now,
      statuses: %w[accepted preparing],
      user_id: @manager.id
    )

    numbers = orders.map(&:order_number)
    assert_includes numbers, @linked_order.order_number
    assert_not_includes numbers, @unlinked_order.order_number
  end

  test "returns empty when no linked sales points" do
    PrepKitchen::SalesPointRegistry.unlink!(prep_kitchen_tenant: @kitchen, sales_point_tenant_id: @point_a.id)

    orders = PrepKitchen::Queue::LinkedSalesPointOrdersQuery.call(
      prep_kitchen_tenant_id: @kitchen.id,
      from: 3.hours.ago,
      to: 1.hour.from_now,
      statuses: %w[accepted preparing],
      user_id: @manager.id
    )

    assert_empty orders
  end

  private

  def create_accepted_order!(tenant:, product:, order_number:)
    disable_rls_once!
    order = Order.create!(
      tenant: tenant,
      order_number: order_number,
      source: "mobile",
      status: "accepted",
      total_amount: 199,
      discount_amount: 0,
      final_amount: 199,
      created_at: 30.minutes.ago
    )
    OrderItem.create!(
      order: order,
      product_id: product.id,
      product_name: product.name,
      quantity: 1,
      unit_price: 199,
      total_price: 199
    )
    order
  end
end
