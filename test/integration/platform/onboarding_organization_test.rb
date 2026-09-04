# frozen_string_literal: true

require "test_helper"

# В2 ONBOARDING_CHECKLIST §1 — организация в УК (/admin = namespace platform).
class Platform::OnboardingOrganizationTest < ActionDispatch::IntegrationTest
  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false
    @uk = create_uk_admin!(email: "uk-onboard-org-#{SecureRandom.hex(3)}@test.local")
    login_as!(@uk)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "GET /admin/organizations/new shows name and slug fields" do
    get new_platform_organization_path

    assert_response :success
    assert_match %r{/admin/organizations}, request.path
    assert_select "input[name='organization[name]']"
    assert_select "input[name='organization[slug]']"
  end

  test "POST creates organization and it appears in index list" do
    slug = "onboard-org-#{SecureRandom.hex(4)}"
    name = "Onboard Org #{slug}"

    assert_difference -> { Organization.count }, +1 do
      post platform_organizations_path, params: { organization: { name: name, slug: slug } }
    end

    assert_redirected_to platform_organizations_path

    org = Organization.find_by!(slug: slug)
    # UkCatalogScope lists only orgs with active sales_point — attach one for index visibility.
    create_tenant!(organization: org, name: "Point #{slug}", slug: "point-#{slug}")

    get platform_organizations_path
    assert_response :success
    assert_match name, response.body
    assert_match slug, response.body
  end

  test "new tenant from org index link is bound to that organization" do
    org = create_organization!(slug: "parent-org-#{SecureRandom.hex(3)}", name: "Parent Org")

    get new_platform_tenant_path(organization_id: org.id)
    assert_response :success
    assert_select "select[name='tenant[organization_id]'] option[selected][value='#{org.id}']"

    tenant_slug = "onboard-tenant-#{SecureRandom.hex(4)}"
    assert_difference -> { Tenant.count }, +1 do
      post platform_tenants_path, params: {
        tenant: {
          organization_id: org.id,
          name: "Onboard Point",
          slug: tenant_slug,
          type: "sales_point",
          status: "active",
          country: "RU",
          currency: "RUB",
          timezone: "Europe/Moscow"
        },
        weekday_schedules: default_weekday_schedules_params,
        modules: { "menu" => "1", "barista" => "1" }
      }
    end

    tenant = Tenant.find_by!(slug: tenant_slug)
    assert_equal org.id, tenant.organization_id
  end
end
