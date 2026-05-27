# frozen_string_literal: true

require "test_helper"

class Platform::TenantOnboarding::EntryPointsTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @org = create_organization!(name: "Test Org")
    @shop_domain_prev = ENV["SHOP_BASE_DOMAIN"]
  end

  teardown do
    ENV["SHOP_BASE_DOMAIN"] = @shop_domain_prev
  end

  test "build includes org slug address and subdomain shop url when SHOP_BASE_DOMAIN set" do
    ENV["SHOP_BASE_DOMAIN"] = "shop.example.com"
    tenant = create_tenant!(
      organization: @org,
      slug: "cafe-ep-#{SecureRandom.hex(2)}"
    )
    tenant.update!(city: "Moscow", address: "Lenina 1")
    TenantModuleFlags.sync!(tenant, { "menu" => "1", "barista" => "1", "kiosk" => "0" })

    data = Platform::TenantOnboarding::EntryPoints.for(tenant, host: "admin.example.com")

    assert_equal "Test Org", data[:organization_name]
    assert_equal tenant.slug, data[:slug]
    assert_equal "Lenina 1", data[:address]
    assert_equal "Moscow", data[:city]
    assert_match %r{http://#{tenant.slug}\.shop\.example\.com/shop}, data[:shop_public_url]
    assert_not data[:kiosk_enabled]
    assert_includes data[:modules].map(&:code), "menu"
    assert data[:modules].find { |m| m.code == "menu" }.enabled
    assert_not data[:modules].find { |m| m.code == "kiosk" }.enabled
  end

  test "build uses tenant_id shop url without SHOP_BASE_DOMAIN" do
    ENV.delete("SHOP_BASE_DOMAIN")
    tenant = create_tenant!(organization: @org, slug: "no-domain-#{SecureRandom.hex(2)}")
    TenantModuleFlags.sync!(tenant, { "menu" => "1" })

    data = Platform::TenantOnboarding::EntryPoints.for(tenant, host: "localhost:3001")

    assert_match %r{/shop\?tenant_id=#{tenant.id}}, data[:shop_public_url]
    assert_match(/tenant_id/, data[:qr_hint])
  end

  test "staff items reflect assigned roles on sales point" do
    tenant = create_tenant!(organization: @org, slug: "staff-sp-#{SecureRandom.hex(2)}")
    create_user!(tenant: tenant, role_codes: %w[barista], email: "bar-#{SecureRandom.hex(3)}@test.local")

    data = Platform::TenantOnboarding::EntryPoints.for(tenant)

    barista = data[:staff_items].find { |i| i.code == "barista" }
    gm = data[:staff_items].find { |i| i.code == "general_manager" }
    assert barista.filled
    assert_not gm.filled
  end

  test "production kitchen staff checklist uses prep_kitchen roles" do
    tenant = create_tenant!(organization: @org, slug: "kitchen-ep-#{SecureRandom.hex(2)}")
    tenant.update!(type: "production_kitchen")
    TenantModuleFlags.sync!(tenant, { "prep_kitchen" => "1" })

    data = Platform::TenantOnboarding::EntryPoints.for(tenant)

    codes = data[:staff_items].map(&:code)
    assert_includes codes, "prep_kitchen_manager"
    assert_includes codes, "prep_kitchen_worker"
    assert_not_includes codes, "barista"
  end
end
