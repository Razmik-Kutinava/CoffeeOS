# frozen_string_literal: true

require "test_helper"

# В2 ONBOARDING_CHECKLIST §7 — инфра URL/DNS/slug.
class Platform::OnboardingInfraTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "onboard-infra-org-#{SecureRandom.hex(3)}")
    anchor = create_tenant!(organization: @org, slug: "onboard-infra-anchor-#{SecureRandom.hex(4)}")
    @uk = create_user!(
      tenant: anchor,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-infra-#{SecureRandom.hex(3)}@test.local",
      password: "pass123"
    )
    login_as!(@uk)

    @shop_domain_prev = ENV["SHOP_BASE_DOMAIN"]
  end

  teardown do
    ENV["SHOP_BASE_DOMAIN"] = @shop_domain_prev
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "fly demo mode without SHOP_BASE_DOMAIN uses tenant_id shop url on card" do
    ENV.delete("SHOP_BASE_DOMAIN")
    slug = "onboard-infra-fly-#{SecureRandom.hex(4)}"

    post platform_tenants_path, params: sales_point_payload(slug: slug)
    tenant = Tenant.find_by!(slug: slug)

    follow_redirect!
    assert_match %r{/shop\?tenant_id=#{tenant.id}}, response.body
  end

  test "mode A with SHOP_BASE_DOMAIN shows subdomain shop url on card" do
    ENV["SHOP_BASE_DOMAIN"] = "shop.example.com"
    slug = "onboard-infra-a-#{SecureRandom.hex(4)}"

    post platform_tenants_path, params: sales_point_payload(slug: slug)

    follow_redirect!
    assert_match %r{http://#{slug}\.shop\.example\.com/shop}, response.body
  end

  test "wildcard subdomain host resolves tenant on shop api when SHOP_BASE_DOMAIN set" do
    ENV["SHOP_BASE_DOMAIN"] = "shop.example.com"
    slug = "onboard-infra-dns-#{SecureRandom.hex(4)}"
    post platform_tenants_path, params: sales_point_payload(slug: slug)

    host! "#{slug}.shop.example.com"
    get "/shop/api/categories"
    assert_response :success
  end

  test "uk cannot create tenant with reserved slug" do
    assert_no_difference -> { Tenant.count } do
      post platform_tenants_path, params: sales_point_payload(slug: "admin", name: "Reserved Admin")
    end
    assert_response :unprocessable_entity
    assert_match(/зарезервирован/i, response.body)
  end

  test "reserved slug falls back to tenant_id url even with SHOP_BASE_DOMAIN" do
    ENV["SHOP_BASE_DOMAIN"] = "shop.example.com"
    # Model blocks create — UrlBuilder still safe if legacy row existed:
    tenant = create_tenant!(organization: @org, slug: "legacy-#{SecureRandom.hex(3)}")
    tenant.update_column(:slug, "www")

    url = Platform::TenantOnboarding::UrlBuilder.shop_url_for(tenant)
    assert_match %r{/shop\?tenant_id=#{tenant.id}}, url
    assert_nil Platform::TenantOnboarding::UrlBuilder.tenant_id_for_host("www.shop.example.com")
  end

  private

  def sales_point_payload(slug:, name: "Infra Point")
    {
      tenant: {
        organization_id: @org.id,
        name: name,
        slug: slug,
        type: "sales_point",
        status: "active",
        city: "Infra City",
        address: "Infra 1",
        country: "RU",
        currency: "RUB",
        timezone: "Europe/Moscow"
      },
      modules: { "menu" => "1", "barista" => "0", "kiosk" => "0" }
    }
  end
end
