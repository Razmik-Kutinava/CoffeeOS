# frozen_string_literal: true

require "test_helper"

class Platform::UkCatalogScopeTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @org = create_organization!(slug: "uk-scope-org-#{SecureRandom.hex(3)}")
    @org_junk = create_organization!(slug: "uk-scope-junk-#{SecureRandom.hex(3)}")
    @point_a = create_tenant!(
      slug: Platform::SinglePointMode::POINT_A_SLUG,
      name: "Demo Coffee Point A",
      organization: @org,
      status: "active"
    )
    @point_b = create_tenant!(
      slug: "uk-scope-b-#{SecureRandom.hex(4)}",
      name: "Point B",
      organization: @org,
      status: "inactive"
    )
    @point_c_active = create_tenant!(
      slug: "uk-scope-c-#{SecureRandom.hex(4)}",
      name: "Point C active",
      organization: @org_junk,
      status: "active"
    )
    @kitchen = create_prep_kitchen_tenant!(organization: @org, status: "active")
  end

  test "default mode lists only active sales points" do
    old = ENV["DEMO_SINGLE_POINT"]
    ENV.delete("DEMO_SINGLE_POINT")

    slugs = Platform::UkCatalogScope.tenants.pluck(:slug)

    assert_includes slugs, @point_a.slug
    assert_includes slugs, @point_c_active.slug
    assert_not_includes slugs, @point_b.slug
    assert_not_includes slugs, @kitchen.slug
  ensure
    old.nil? ? ENV.delete("DEMO_SINGLE_POINT") : ENV["DEMO_SINGLE_POINT"] = old
  end

  test "single point mode lists only canonical point a" do
    old = ENV["DEMO_SINGLE_POINT"]
    ENV["DEMO_SINGLE_POINT"] = "true"

    tenants = Platform::UkCatalogScope.tenants
    orgs = Platform::UkCatalogScope.organizations

    assert_equal 1, tenants.count
    assert_equal @point_a.id, tenants.first.id
    assert_equal 1, orgs.count
    assert_equal @org.id, orgs.first.id
  ensure
    old.nil? ? ENV.delete("DEMO_SINGLE_POINT") : ENV["DEMO_SINGLE_POINT"] = old
  end
end
