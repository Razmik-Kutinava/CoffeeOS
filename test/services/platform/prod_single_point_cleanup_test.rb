# frozen_string_literal: true

require "test_helper"

class Platform::ProdSinglePointCleanupTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @org = create_organization!(slug: "demo-coffeeos-cleanup-#{SecureRandom.hex(3)}")
    @point_a = create_tenant!(
      slug: "point-a-cleanup-#{SecureRandom.hex(4)}",
      name: "Demo Coffee Point A",
      organization: @org,
      city: "Москва",
      address: "ул. Ленина, 10"
    )
    @point_b = create_tenant!(
      slug: "point-b-cleanup-#{SecureRandom.hex(4)}",
      name: "Demo Coffee Point B",
      organization: @org,
      city: "Москва"
    )
    @kitchen = create_prep_kitchen_tenant!(
      slug: "kitchen-cleanup-#{SecureRandom.hex(4)}",
      organization: @org
    )
    @mcp_junk = create_tenant!(
      slug: "mcp-point-#{SecureRandom.hex(4)}",
      name: "MCP Junk",
      organization: @org
    )
    @opts = { point_a_id: @point_a.id, keep_tenant_ids: [ @point_a.id ] }
  end

  test "dry_run lists tenants to deactivate without changing status" do
    result = Platform::ProdSinglePointCleanup.call(dry_run: true, keep_kitchen: true, **@opts)

    assert result.dry_run
    assert_equal @point_a.id.to_s, result.point_a[:id].to_s
    slugs = result.deactivated.map { |r| r[:slug] }
    assert_includes slugs, @point_b.slug
    assert_includes slugs, @mcp_junk.slug
    assert_not_includes slugs, @point_a.slug
    assert_not_includes slugs, @kitchen.slug

    assert_equal "active", @point_b.reload.status
    assert result.verification[:pass]
  end

  test "apply deactivates extra sales_points in scope and keeps kitchen active" do
    result = Platform::ProdSinglePointCleanup.call(dry_run: false, keep_kitchen: true, **@opts)

    assert_not result.dry_run
    assert_equal "active", @point_a.reload.status
    assert_equal "inactive", @point_b.reload.status
    assert_equal "inactive", @mcp_junk.reload.status
    assert_equal "active", @kitchen.reload.status
    assert result.verification[:orders_preserved]
    assert result.verification[:payments_preserved]
  end

  test "resolves canonical prod point a by slug when id exists" do
    canonical = Tenant.find_by(id: Platform::ProdSinglePointCleanup::POINT_A_TENANT_ID) ||
                Tenant.find_by(slug: Platform::ProdSinglePointCleanup::POINT_A_SLUG)
    skip "canonical Point A not in test DB" unless canonical

    result = Platform::ProdSinglePointCleanup.call(dry_run: true, keep_kitchen: false)

    assert_equal canonical.id.to_s, result.point_a[:id].to_s
  end
end
