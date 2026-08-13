# frozen_string_literal: true

require "test_helper"

# В2 ONBOARDING_CHECKLIST §5 — staff для боевых входов.
class Platform::OnboardingStaffTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "onboard-staff-org-#{SecureRandom.hex(3)}")
    anchor = create_tenant!(organization: @org, slug: "onboard-staff-anchor-#{SecureRandom.hex(4)}")
    @uk = create_user!(
      tenant: anchor,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-staff-#{SecureRandom.hex(3)}@test.local",
      password: "pass123"
    )
    login_as!(@uk)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "uk open_as_manager switches tenant context for each sales point" do
    tenants = 3.times.map do |i|
      slug = "onboard-staff-sp-#{i}-#{SecureRandom.hex(3)}"
      post platform_tenants_path, params: sales_point_payload(slug: slug, name: "Staff Point #{i + 1}")
      assert_response :redirect
      Tenant.find_by!(slug: slug)
    end

    tenants.each do |tenant|
      post open_as_manager_platform_tenant_path(tenant)
      assert_redirected_to manager_dashboard_path
      assert_equal tenant.id.to_s, session[:manager_tenant_id]

      get manager_dashboard_path
      assert_response :success
    end
  end

  test "open_as_manager with to staff lands on manager staff index" do
    slug = "onboard-staff-link-#{SecureRandom.hex(4)}"
    post platform_tenants_path, params: sales_point_payload(slug: slug, name: "Staff Link Point")
    tenant = Tenant.find_by!(slug: slug)

    post open_as_manager_platform_tenant_path(tenant, to: "staff")
    assert_redirected_to manager_staff_members_path
    assert_equal tenant.id.to_s, session[:manager_tenant_id]

    follow_redirect!
    assert_response :success
    assert_match "staff", response.body.downcase
  end

  test "barista created via uk manager staff logs into barista panel" do
    slug = "onboard-staff-barista-#{SecureRandom.hex(4)}"
    post platform_tenants_path, params: sales_point_payload(slug: slug, name: "Barista Point")
    tenant = Tenant.find_by!(slug: slug)

    post open_as_manager_platform_tenant_path(tenant)
    assert_redirected_to manager_dashboard_path

    email = "barista-#{SecureRandom.hex(4)}@test.local"
    password = "staff-pass-#{SecureRandom.hex(3)}"
    assert_difference -> { User.count }, +1 do
      post manager_staff_members_path, params: {
        user: { name: "Barista Staff", email: email, password: password },
        role_codes: %w[barista]
      }
    end
    assert_redirected_to manager_staff_members_path

    barista = User.find_by!(email: email)
    assert barista.has_role?("barista")
    assert_equal tenant.id, barista.tenant_id

    delete logout_path
    assert_redirected_to login_path

    post "/login", params: { email: email, password: password }
    assert_redirected_to barista_dashboard_path
    follow_redirect!

    get barista_dashboard_path
    assert_response :success
  end

  test "general_manager created via uk manager staff logs into manager panel" do
    slug = "onboard-staff-gm-#{SecureRandom.hex(4)}"
    post platform_tenants_path, params: sales_point_payload(slug: slug, name: "GM Point")
    tenant = Tenant.find_by!(slug: slug)

    post open_as_manager_platform_tenant_path(tenant)

    email = "gm-#{SecureRandom.hex(4)}@test.local"
    password = "gm-pass-#{SecureRandom.hex(3)}"
    post manager_staff_members_path, params: {
      user: { name: "GM Staff", email: email, password: password },
      role_codes: %w[general_manager]
    }

    gm = User.find_by!(email: email)
    assert gm.has_role?("general_manager")

    delete logout_path
    post "/login", params: { email: email, password: password }
    assert_redirected_to manager_dashboard_path
    follow_redirect!

    get manager_staff_members_path
    assert_response :success
  end

  test "manager staff edit leaves password unchanged when blank and accepts new password" do
    slug = "onboard-staff-pw-#{SecureRandom.hex(4)}"
    post platform_tenants_path, params: sales_point_payload(slug: slug, name: "Password Point")
    tenant = Tenant.find_by!(slug: slug)

    post open_as_manager_platform_tenant_path(tenant)

    email = "pw-#{SecureRandom.hex(4)}@test.local"
    initial = "initial-#{SecureRandom.hex(3)}"
    post manager_staff_members_path, params: {
      user: { name: "PW User", email: email, password: initial },
      role_codes: %w[barista]
    }
    staff = User.find_by!(email: email)

    patch manager_staff_member_path(staff), params: {
      user: { name: "PW User Renamed", email: email, password: "" },
      role_codes: %w[barista]
    }
    assert_redirected_to manager_staff_members_path

    delete logout_path
    post "/login", params: { email: email, password: initial }
    assert_redirected_to barista_dashboard_path

    delete logout_path
    login_as!(@uk)
    post open_as_manager_platform_tenant_path(tenant)

    updated = "updated-#{SecureRandom.hex(3)}"
    patch manager_staff_member_path(staff), params: {
      user: { name: "PW User Renamed", email: email, password: updated },
      role_codes: %w[barista]
    }
    assert_redirected_to manager_staff_members_path

    delete logout_path
    post "/login", params: { email: email, password: updated }
    assert_redirected_to barista_dashboard_path
  end

  private

  def sales_point_payload(slug:, name:)
    {
      tenant: {
        organization_id: @org.id,
        name: name,
        slug: slug,
        type: "sales_point",
        status: "active",
        city: "Staff City",
        address: "Staff St 1",
        country: "RU",
        currency: "RUB",
        timezone: "Europe/Moscow"
      },
      weekday_schedules: default_weekday_schedules_params,
      modules: { "menu" => "1", "barista" => "1", "kiosk" => "0" }
    }
  end
end
