# frozen_string_literal: true

require "test_helper"

class PrepKitchen::SalesPointRegistryTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @kitchen = create_prep_kitchen_tenant!
    @point_a = create_tenant!(name: "Point A", slug: "pk-sp-a-#{SecureRandom.hex(3)}")
    @point_b = create_tenant!(name: "Point B", slug: "pk-sp-b-#{SecureRandom.hex(3)}")
    Current.tenant_id = @kitchen.id
  end

  teardown do
    Current.reset
  end

  test "links kitchen to multiple sales points" do
    PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @kitchen, sales_point_tenant: @point_a)
    PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @kitchen, sales_point_tenant: @point_b)

    points = PrepKitchen::SalesPointRegistry.sales_points_for(@kitchen.id)
    assert_equal 2, points.count
    assert_equal [@point_a.id, @point_b.id].sort, points.pluck(:id).sort
  end

  test "resolves prep kitchen from sales point" do
    PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @kitchen, sales_point_tenant: @point_a)

    assert_equal @kitchen, PrepKitchen::SalesPointRegistry.prep_kitchen_for(@point_a.id)
    assert PrepKitchen::SalesPointRegistry.serves_sales_point?(
      prep_kitchen_tenant_id: @kitchen.id,
      sales_point_tenant_id: @point_a.id
    )
  end

  test "rejects invalid tenant types" do
    assert_raises(PrepKitchen::SalesPointRegistry::Error) do
      PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @point_a, sales_point_tenant: @point_b)
    end
  end

  test "unlink removes association" do
    PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @kitchen, sales_point_tenant: @point_a)
    PrepKitchen::SalesPointRegistry.unlink!(prep_kitchen_tenant: @kitchen, sales_point_tenant_id: @point_a.id)

    assert_empty PrepKitchen::SalesPointRegistry.sales_points_for(@kitchen.id)
  end

  test "candidate_sales_points excludes already linked" do
    PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @kitchen, sales_point_tenant: @point_a)
    org = Organization.create!(name: "Org2", slug: "org2-#{SecureRandom.hex(3)}")
    @kitchen.update!(organization: org)
    @point_a.update!(organization: org)
    @point_b.update!(organization: org)

    candidates = PrepKitchen::SalesPointRegistry.candidate_sales_points_for(@kitchen)
    assert_includes candidates.pluck(:id), @point_b.id
    assert_not_includes candidates.pluck(:id), @point_a.id
  end
end
