# frozen_string_literal: true

require "test_helper"

class PrepKitchen::QueueControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = Organization.create!(name: "Queue UI Org", slug: "q-ui-org-#{SecureRandom.hex(4)}")
    @kitchen = create_prep_kitchen_tenant!(organization: @org)
    @point_a = create_tenant!(name: "Queue UI A", slug: "q-ui-a-#{SecureRandom.hex(4)}", organization: @org)
    @point_b = create_tenant!(name: "Queue UI B", slug: "q-ui-b-#{SecureRandom.hex(4)}", organization: @org)

    category = create_category!
    @product = create_product!(category: category, name: "Queue UI Cappuccino")
    enable_product_for_tenant!(tenant: @point_a, product: @product, price: 210)

    PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @kitchen, sales_point_tenant: @point_a)

    @linked_order = create_accepted_order!(
      tenant: @point_a,
      product: @product,
      order_number: "PK-UI-LINK-01"
    )
    create_accepted_order!(
      tenant: @point_b,
      product: @product,
      order_number: "PK-UI-FOREIGN-02"
    )

    @manager = create_user!(
      tenant: @kitchen,
      role_codes: %w[prep_kitchen_manager],
      email: "pk-queue-#{SecureRandom.hex(3)}@test.local"
    )
    login_as!(@manager)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "queue shows demand from linked sales point orders only" do
    get prep_kitchen_queue_path
    assert_response :success

    assert_match @product.name, response.body
    assert_match @linked_order.order_number, response.body
    assert_match @point_a.name, response.body
    assert_no_match "PK-UI-FOREIGN-02", response.body
  end

  private

  def create_accepted_order!(tenant:, product:, order_number:)
    disable_rls_once!
    order = Order.create!(
      tenant: tenant,
      order_number: order_number,
      source: "mobile",
      status: "accepted",
      total_amount: 210,
      discount_amount: 0,
      final_amount: 210,
      created_at: 30.minutes.ago
    )
    OrderItem.create!(
      order: order,
      product_id: product.id,
      product_name: product.name,
      quantity: 1,
      unit_price: 210,
      total_price: 210
    )
    order
  end
end
