# frozen_string_literal: true

require "test_helper"

class Platform::PrepKitchenLinksControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = Organization.create!(name: "Platform PK Org", slug: "plat-pk-#{SecureRandom.hex(4)}")
    @kitchen = create_tenant!(
      name: "Platform Kitchen",
      slug: "plat-k-#{SecureRandom.hex(4)}",
      type: "production_kitchen",
      organization: @org
    )
    @point_a = create_tenant!(name: "Platform Point A", slug: "plat-a-#{SecureRandom.hex(4)}", organization: @org)
    @point_b = create_tenant!(name: "Platform Point B", slug: "plat-b-#{SecureRandom.hex(4)}", organization: @org)
    FeatureFlag.create!(tenant: @kitchen, module: "prep_kitchen", enabled: true)

    @uk = create_uk_admin!(email: "uk-pk-links-#{SecureRandom.hex(3)}@test.local")
    login_as!(@uk)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "tenant show lists prep kitchen links card for production kitchen" do
    PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @kitchen, sales_point_tenant: @point_a)

    get platform_tenant_path(@kitchen)
    assert_response :success
    assert_match @point_a.name, response.body
    assert_match @point_b.name, response.body
    assert_match "Точки продаж цеха", response.body
  end

  test "uk admin links and unlinks sales point from platform tenant show" do
    post prep_kitchen_sales_point_links_platform_tenant_path(@kitchen),
         params: { sales_point_tenant_id: @point_a.id }
    assert_redirected_to platform_tenant_path(@kitchen)

    assert PrepKitchen::SalesPointRegistry.serves_sales_point?(
      prep_kitchen_tenant_id: @kitchen.id,
      sales_point_tenant_id: @point_a.id
    )

    delete prep_kitchen_sales_point_link_platform_tenant_path(@kitchen, @point_a)
    assert_redirected_to platform_tenant_path(@kitchen)

    assert_not PrepKitchen::SalesPointRegistry.serves_sales_point?(
      prep_kitchen_tenant_id: @kitchen.id,
      sales_point_tenant_id: @point_a.id
    )
  end
end
