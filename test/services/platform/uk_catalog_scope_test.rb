# frozen_string_literal: true

require "test_helper"

class Platform::UkCatalogScopeTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @org = create_organization!(slug: "uk-scope-org-#{SecureRandom.hex(3)}")
    @org_empty = create_organization!(slug: "uk-scope-empty-#{SecureRandom.hex(3)}")
    @point_a = create_tenant!(
      slug: Platform::SinglePointMode::POINT_A_SLUG,
      name: "Витрина А",
      organization: @org,
      status: "active"
    )
    @point_b = create_tenant!(
      slug: "uk-scope-b-#{SecureRandom.hex(4)}",
      name: "Point B",
      organization: @org,
      status: "inactive"
    )
    @kitchen = create_prep_kitchen_tenant!(organization: @org, status: "active")
  end

  test "lists all points: sales points, kitchens and inactive" do
    slugs = Platform::UkCatalogScope.tenants.pluck(:slug)

    assert_includes slugs, @point_a.slug
    assert_includes slugs, @point_b.slug
    assert_includes slugs, @kitchen.slug
  end

  test "lists all organizations including ones without points" do
    ids = Platform::UkCatalogScope.organizations.pluck(:id)

    assert_includes ids, @org.id
    assert_includes ids, @org_empty.id
  end

  test "DEMO_SINGLE_POINT no longer hides other points" do
    old = ENV["DEMO_SINGLE_POINT"]
    ENV["DEMO_SINGLE_POINT"] = "true"

    slugs = Platform::UkCatalogScope.tenants.pluck(:slug)

    assert_includes slugs, @point_b.slug
    assert_includes slugs, @kitchen.slug
  ensure
    old.nil? ? ENV.delete("DEMO_SINGLE_POINT") : ENV["DEMO_SINGLE_POINT"] = old
  end
end
