# frozen_string_literal: true

require "test_helper"

# В2 ONBOARDING_CHECKLIST §4 — карточка «все входы».
class Platform::OnboardingEntryPointsTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(name: "Entry Org", slug: "entry-org-#{SecureRandom.hex(3)}")
    anchor = create_tenant!(organization: @org, slug: "entry-anchor-#{SecureRandom.hex(4)}")
    @uk = create_user!(
      tenant: anchor,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-ep-#{SecureRandom.hex(3)}@test.local",
      password: "pass123"
    )
    login_as!(@uk)

    @shop_domain_prev = ENV["SHOP_BASE_DOMAIN"]
    ENV["SHOP_BASE_DOMAIN"] = "shop.example.com"
  end

  teardown do
    ENV["SHOP_BASE_DOMAIN"] = @shop_domain_prev
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "create redirects to tenant show card with entry points" do
    slug = "entry-card-#{SecureRandom.hex(4)}"

    post platform_tenants_path, params: {
      tenant: {
        organization_id: @org.id,
        name: "Card Point",
        slug: slug,
        type: "sales_point",
        status: "active",
        city: "Kazan",
        address: "Bauman 5",
        country: "RU",
        currency: "RUB",
        timezone: "Europe/Moscow"
      },
      weekday_schedules: default_weekday_schedules_params,
      modules: { "menu" => "1", "barista" => "1", "kiosk" => "0" }
    }

    tenant = Tenant.find_by!(slug: slug)
    assert_redirected_to platform_tenant_path(tenant)

    follow_redirect!
    assert_response :success
    assert_select "h2", text: "Входы и URL"
    assert_match "Entry Org", response.body
    assert_match slug, response.body
    assert_match "Bauman 5", response.body
    assert_match "Kazan", response.body
    assert_match %r{#{slug}\.shop\.example\.com/shop}, response.body
    assert_match "/login", response.body
    assert_match "/manager", response.body
    assert_match "/barista", response.body
    assert_match "/prep_kitchen", response.body
    assert_match "Меню точки", response.body
    assert_match "Киоск", response.body
    assert_match "Бариста", response.body
    assert_select "button", text: "Копировать"
  end

  test "edit page includes entry points card" do
    tenant = create_tenant!(
      organization: @org,
      slug: "entry-edit-#{SecureRandom.hex(4)}"
    )
    tenant.update!(city: "SPB", address: "Nevsky 1")
    TenantModuleFlags.sync!(tenant, { "menu" => "1", "barista" => "1", "kiosk" => "0" })

    get edit_platform_tenant_path(tenant)

    assert_response :success
    assert_select "h2", text: "Входы и URL"
    assert_match "Nevsky 1", response.body
  end

  test "index lists card link for tenant" do
    tenant = create_tenant!(organization: @org, slug: "entry-index-#{SecureRandom.hex(4)}")

    get platform_tenants_path

    assert_response :success
    assert_select "a[href=?]", platform_tenant_path(tenant), text: "Карточка"
  end
end
