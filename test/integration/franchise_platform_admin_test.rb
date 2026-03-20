# frozen_string_literal: true

require "test_helper"

class FranchisePlatformAdminTest < ActionDispatch::IntegrationTest
  test "uk global admin sees platform dashboard after login" do
    uk = create_uk_admin!(email: "uk-dash@test.local")
    login_as!(uk, password: "pass123")
    assert_response :success
    assert_includes @response.body, "УК"
  end

  test "uk creates organization and tenant with modules" do
    uk = create_uk_admin!(email: "uk-org@test.local")
    login_as!(uk, password: "pass123")

    slug = "acme-#{SecureRandom.hex(3)}"
    assert_difference -> { Organization.count }, +1 do
      post platform_organizations_path, params: { organization: { name: "Acme", slug: slug } }
    end
    org = Organization.find_by!(slug: slug)

    assert_difference -> { Tenant.count }, +1 do
      post platform_tenants_path, params: {
        tenant: {
          organization_id: org.id,
          name: "Точка 1",
          slug: "t1-#{SecureRandom.hex(3)}",
          type: "sales_point",
          status: "active",
          country: "RU",
          currency: "RUB",
          timezone: "Europe/Moscow"
        },
        modules: { "kiosk" => "1", "menu" => "1" }
      }
    end
    assert_redirected_to platform_tenants_path
    t = Tenant.order(:created_at).last
    assert_equal org.id, t.organization_id
    assert FeatureFlag.find_by(tenant_id: t.id, module: "kiosk")&.enabled
  end

  test "franchise owner switches tenant and creates office manager" do
    org = create_organization!
    t1 = create_tenant!(organization: org, name: "A", slug: "a-#{SecureRandom.hex(3)}")
    t2 = create_tenant!(organization: org, name: "B", slug: "b-#{SecureRandom.hex(3)}")
    owner = create_user!(
      tenant: t1,
      organization: org,
      role_codes: %w[franchise_manager],
      email: "own-#{SecureRandom.hex(4)}@test.local"
    )

    login_as!(owner, password: "pass123")
    assert_response :success

    post manager_switch_tenant_path, params: { tenant_id: t2.id }
    follow_redirect!
    assert_response :success

    assert_difference -> { User.count }, +1 do
      post manager_staff_members_path, params: {
        user: {
          name: "Офис",
          email: "om-#{SecureRandom.hex(4)}@test.local",
          password: "pass123"
        },
        role_codes: ["office_manager"]
      }
    end
    assert_redirected_to manager_staff_members_path
  end

  test "office manager cannot keep office_manager role when creating staff" do
    org = create_organization!
    t = create_tenant!(organization: org)
    om = create_user!(tenant: t, role_codes: %w[office_manager], email: "om-y@test.local")

    login_as!(om, password: "pass123")

    em = "x-#{SecureRandom.hex(4)}@test.local"
    assert_difference -> { User.count }, +1 do
      post manager_staff_members_path, params: {
        user: {
          name: "X",
          email: em,
          password: "pass123"
        },
        role_codes: %w[office_manager barista]
      }
    end
    assert_redirected_to manager_staff_members_path
    nu = User.find_by!(email: em)
    assert nu.roles.exists?(code: "barista")
    assert_not nu.roles.exists?(code: "office_manager")
  end

  test "health tenant json requires uk session" do
    t = create_tenant!
    get health_tenant_path(t)
    assert_response :unauthorized

    uk = create_uk_admin!(email: "uk-h2@test.local")
    login_as!(uk, password: "pass123")

    get health_tenant_path(t)
    assert_response :success
    body = JSON.parse(@response.body)
    assert body["overall"].present? || body["checks"].present?
  end
end
