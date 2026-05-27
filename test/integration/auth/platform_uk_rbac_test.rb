# frozen_string_literal: true

require "test_helper"

# Веха 1 / блок C: platform / УК — org, tenant, выдача доступов; только uk_global_admin.
class Auth::PlatformUkRbacTest < ActionDispatch::IntegrationTest
  UK_PATHS = [
    [:root, :platform_root_path],
    [:organizations, :platform_organizations_path],
    [:tenants, :platform_tenants_path],
    [:menu, :platform_menu_path]
  ].freeze

  FORBIDDEN_ROLES = {
    barista: %w[barista],
    general_manager: %w[general_manager],
    franchise_manager: %w[franchise_manager]
  }.freeze

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "uk-org-#{SecureRandom.hex(3)}")
    @anchor = create_tenant!(organization: @org, slug: "uk-anchor-#{SecureRandom.hex(4)}")
    @uk = create_uk_admin!(email: "uk-rbac-#{SecureRandom.hex(3)}@test.local")
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "uk_global_admin can access platform admin pages" do
    login_as!(@uk)

    UK_PATHS.each do |_name, path_helper|
      get send(path_helper)
      assert_response :success, "УК должен открывать #{path_helper}"
    end
  end

  test "non uk roles are redirected from platform admin" do
    FORBIDDEN_ROLES.each do |role_name, role_codes|
      user = create_user!(
        tenant: @anchor,
        organization: @org,
        role_codes: role_codes,
        email: "#{role_name}-#{SecureRandom.hex(3)}@test.local"
      )
      login_as!(user)

      get platform_root_path
      assert_response :redirect, "#{role_name} не должен видеть /admin"
    end
  end

  test "uk creates organization" do
    login_as!(@uk)
    slug = "uk-new-org-#{SecureRandom.hex(3)}"

    assert_difference -> { Organization.count }, +1 do
      post platform_organizations_path, params: { organization: { name: "UK Org", slug: slug } }
    end

    assert_redirected_to platform_organizations_path
    assert Organization.find_by!(slug: slug)
  end

  test "uk creates tenant with modules via onboarding provision" do
    login_as!(@uk)
    slug = "uk-tenant-#{SecureRandom.hex(4)}"

    assert_difference -> { Tenant.count }, +1 do
      post platform_tenants_path, params: {
        tenant: {
          organization_id: @org.id,
          name: "UK Point",
          slug: slug,
          type: "sales_point",
          status: "active",
          country: "RU",
          currency: "RUB",
          timezone: "Europe/Moscow"
        },
        modules: { "menu" => "1", "barista" => "1" }
      }
    end

    tenant = Tenant.find_by!(slug: slug)
    assert_redirected_to platform_tenant_path(tenant)
    assert FeatureFlag.find_by(tenant_id: tenant.id, module: "menu")&.enabled
  end

  test "uk grants franchise_manager access for organization" do
    login_as!(@uk)
    email = "owner-#{SecureRandom.hex(4)}@test.local"

    assert_difference -> { User.count }, +1 do
      post platform_franchise_owners_path, params: {
        user: {
          name: "Franchise Owner",
          email: email,
          password: "pass123456",
          organization_id: @org.id
        }
      }
    end

    assert_redirected_to platform_root_path
    owner = User.find_by!(email: email)
    assert owner.franchise_manager?
    assert_equal @org.id, owner.organization_id
  end

  test "uk can open tenant as manager panel" do
    login_as!(@uk)

    post open_as_manager_platform_tenant_path(@anchor)
    assert_redirected_to manager_dashboard_path
    assert_equal @anchor.id.to_s, session[:manager_tenant_id]
  end

  test "general_manager cannot create organization via platform" do
    gm = create_user!(
      tenant: @anchor,
      role_codes: %w[general_manager],
      email: "gm-block-#{SecureRandom.hex(3)}@test.local"
    )
    login_as!(gm)

    assert_no_difference -> { Organization.count } do
      post platform_organizations_path, params: {
        organization: { name: "Hack Org", slug: "hack-#{SecureRandom.hex(3)}" }
      }
    end
    assert_response :redirect
  end
end
