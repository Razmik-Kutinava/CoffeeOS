# frozen_string_literal: true

require "test_helper"

class PrepKitchen::StopListControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = Organization.create!(name: "Stop UI Org", slug: "stop-ui-#{SecureRandom.hex(4)}")
    @kitchen = create_prep_kitchen_tenant!(organization: @org)
    @point_a = create_tenant!(name: "Stop UI A", slug: "stop-ui-a-#{SecureRandom.hex(4)}", organization: @org)
    @point_b = create_tenant!(name: "Stop UI B", slug: "stop-ui-b-#{SecureRandom.hex(4)}", organization: @org)

    category = create_category!
    product = create_product!(category: category, name: "Stop UI Cappuccino")
    @linked_setting = enable_product_for_tenant!(tenant: @point_a, product: product, price: 210)
    @linked_setting.update!(is_sold_out: true, sold_out_reason: "manual")
    foreign_setting = enable_product_for_tenant!(tenant: @point_b, product: product, price: 210)
    foreign_setting.update!(is_sold_out: true, sold_out_reason: "manual")

    PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @kitchen, sales_point_tenant: @point_a)

    @manager = create_user!(
      tenant: @kitchen,
      role_codes: %w[prep_kitchen_manager],
      email: "pk-stop-#{SecureRandom.hex(3)}@test.local"
    )
    login_as!(@manager)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "index lists stop list from linked sales point with tenant name" do
    get prep_kitchen_stop_list_path
    assert_response :success

    assert_match @point_a.name, response.body
    assert_match @linked_setting.product.name, response.body
    assert_no_match @point_b.name, response.body
  end

  test "manager clears stop list on linked sales point" do
    patch prep_kitchen_stop_list_item_path(@linked_setting), params: {
      product_tenant_setting: { is_sold_out: "0" }
    }

    assert_response :redirect
    assert_equal false, @linked_setting.reload.is_sold_out
  end
end
