# frozen_string_literal: true

require "test_helper"

class PrepKitchen::SalesPointsControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = Organization.create!(name: "PK Org", slug: "pk-org-#{SecureRandom.hex(4)}")
    @kitchen = create_tenant!(
      name: "PK Kitchen",
      slug: "pk-k-#{SecureRandom.hex(4)}",
      type: "production_kitchen",
      organization: @org
    )
    @point_a = create_tenant!(name: "Point A", slug: "pk-a-#{SecureRandom.hex(4)}", organization: @org)
    @point_b = create_tenant!(name: "Point B", slug: "pk-b-#{SecureRandom.hex(4)}", organization: @org)
    FeatureFlag.create!(tenant: @kitchen, module: "prep_kitchen", enabled: true)

    @manager = create_user!(
      tenant: @kitchen,
      role_codes: %w[prep_kitchen_manager],
      email: "pkm-sp-#{SecureRandom.hex(3)}@test.local"
    )
    login_as!(@manager)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "index lists linked and candidate sales points" do
    PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @kitchen, sales_point_tenant: @point_a)

    get prep_kitchen_sales_points_path
    assert_response :success
    assert_match @point_a.name, response.body
    assert_match @point_b.name, response.body
  end

  test "manager links and unlinks sales point" do
    post prep_kitchen_sales_points_path, params: { sales_point_tenant_id: @point_a.id }
    assert_redirected_to prep_kitchen_sales_points_path

    assert PrepKitchen::SalesPointRegistry.serves_sales_point?(
      prep_kitchen_tenant_id: @kitchen.id,
      sales_point_tenant_id: @point_a.id
    )

    delete prep_kitchen_sales_point_path(@point_a)
    assert_redirected_to prep_kitchen_sales_points_path

    assert_not PrepKitchen::SalesPointRegistry.serves_sales_point?(
      prep_kitchen_tenant_id: @kitchen.id,
      sales_point_tenant_id: @point_a.id
    )
  end

  test "create rejects sales point from another organization" do
    other_org = Organization.create!(name: "Foreign Org", slug: "foreign-org-#{SecureRandom.hex(4)}")
    foreign_point = create_tenant!(name: "Foreign Point", slug: "foreign-pt-#{SecureRandom.hex(4)}", organization: other_org)

    post prep_kitchen_sales_points_path, params: { sales_point_tenant_id: foreign_point.id }
    assert_redirected_to prep_kitchen_sales_points_path

    assert_not PrepKitchen::SalesPointRegistry.serves_sales_point?(
      prep_kitchen_tenant_id: @kitchen.id,
      sales_point_tenant_id: foreign_point.id
    )
    follow_redirect!
    assert_match(/недоступна|organization/i, response.body)
  end
end
