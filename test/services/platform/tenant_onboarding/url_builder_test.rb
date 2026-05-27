# frozen_string_literal: true

require "test_helper"

class Platform::TenantOnboarding::UrlBuilderTest < ActiveSupport::TestCase
  include TestFactories

  test "tenant_id_for_host resolves slug subdomain against SHOP_BASE_DOMAIN" do
    org = create_organization!
    tenant = create_tenant!(organization: org, slug: "cafe-msk-#{SecureRandom.hex(2)}")
    prev = ENV["SHOP_BASE_DOMAIN"]
    ENV["SHOP_BASE_DOMAIN"] = "example.com"
    assert_equal tenant.id, Platform::TenantOnboarding::UrlBuilder.tenant_id_for_host("#{tenant.slug}.example.com")
  ensure
    ENV["SHOP_BASE_DOMAIN"] = prev
  end

  test "tenant_id_for_host returns nil when domain mismatch" do
    prev = ENV["SHOP_BASE_DOMAIN"]
    ENV["SHOP_BASE_DOMAIN"] = "example.com"
    assert_nil Platform::TenantOnboarding::UrlBuilder.tenant_id_for_host("other.net")
  ensure
    ENV["SHOP_BASE_DOMAIN"] = prev
  end

  test "shop_url_for uses tenant_id fallback for reserved slug" do
    org = create_organization!
    tenant = create_tenant!(organization: org, slug: "safe-#{SecureRandom.hex(2)}")
    tenant.update_column(:slug, "api")
    prev = ENV["SHOP_BASE_DOMAIN"]
    ENV["SHOP_BASE_DOMAIN"] = "example.com"

    assert_match %r{/shop\?tenant_id=#{tenant.id}}, Platform::TenantOnboarding::UrlBuilder.shop_url_for(tenant)
    assert_nil Platform::TenantOnboarding::UrlBuilder.tenant_id_for_host("api.example.com")
  ensure
    ENV["SHOP_BASE_DOMAIN"] = prev
  end
end
