# frozen_string_literal: true

require "test_helper"

class PrepKitchen::SalesPointRegistryTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @org = Organization.create!(name: "PK Registry Org", slug: "pk-reg-#{SecureRandom.hex(4)}")
    @kitchen = create_prep_kitchen_tenant!(organization: @org)
    @point_a = create_tenant!(name: "Point A", slug: "pk-sp-a-#{SecureRandom.hex(3)}", organization: @org)
    @point_b = create_tenant!(name: "Point B", slug: "pk-sp-b-#{SecureRandom.hex(3)}", organization: @org)
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
    assert_equal [ @point_a.id, @point_b.id ].sort, points.pluck(:id).sort
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

    candidates = PrepKitchen::SalesPointRegistry.candidate_sales_points_for(@kitchen)
    assert_includes candidates.pluck(:id), @point_b.id
    assert_not_includes candidates.pluck(:id), @point_a.id
  end

  test "rejects cross organization link" do
    other_org = Organization.create!(name: "Other Org", slug: "other-org-#{SecureRandom.hex(3)}")
    foreign_point = create_tenant!(name: "Foreign", slug: "foreign-#{SecureRandom.hex(3)}", organization: other_org)

    error = assert_raises(PrepKitchen::SalesPointRegistry::Error) do
      PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @kitchen, sales_point_tenant: foreign_point)
    end
    assert_match(/same organization/i, error.message)
  end

  test "rejects link when kitchen has no organization" do
    @kitchen.update!(organization_id: nil)
    error = assert_raises(PrepKitchen::SalesPointRegistry::Error) do
      PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @kitchen, sales_point_tenant: @point_a)
    end
    assert_match(/organization/i, error.message)
  end
end
