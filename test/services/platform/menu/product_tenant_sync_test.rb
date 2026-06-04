# frozen_string_literal: true

require "test_helper"

class Platform::Menu::ProductTenantSyncTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @org = create_organization!
    @tenant_a = create_tenant!(organization: @org, slug: "sync-a-#{SecureRandom.hex(2)}")
    @tenant_b = create_tenant!(organization: @org, slug: "sync-b-#{SecureRandom.hex(2)}")
    @uk_user = create_user!(
      tenant: @tenant_a,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-sync-#{SecureRandom.hex(3)}@test.local"
    )
    @category = create_category!
  end

  test "repair_missing_pts! creates settings on all tenants" do
    product = create_product!(category: @category, name: "No PTS", slug: "no-pts-#{SecureRandom.hex(2)}")
    product.update!(base_price: 200, is_active: true)

    expected = Tenant.count
    assert_difference -> { ProductTenantSetting.where(product_id: product.id).count }, expected do
      Platform::Menu::ProductTenantSync.repair_missing_pts!(user: @uk_user)
    end

    pts = ProductTenantSetting.where(product_id: product.id)
    assert pts.all?(&:is_enabled?)
    assert_includes pts.pluck(:tenant_id), @tenant_a.id
    assert_includes pts.pluck(:tenant_id), @tenant_b.id
  end
end
