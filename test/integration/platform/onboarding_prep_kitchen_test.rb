# frozen_string_literal: true

require "test_helper"

# В2 ONBOARDING_CHECKLIST §3 — заготовочный цех через УК.
class Platform::OnboardingPrepKitchenTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "onboard-pk-org-#{SecureRandom.hex(3)}")
    anchor = create_tenant!(organization: @org, slug: "onboard-pk-anchor-#{SecureRandom.hex(4)}")
    @uk = create_user!(
      tenant: anchor,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-pk-#{SecureRandom.hex(3)}@test.local",
      password: "pass123"
    )
    login_as!(@uk)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "uk creates production_kitchen tenant with prep_kitchen module only" do
    slug = "onboard-kitchen-#{SecureRandom.hex(4)}"

    assert_difference -> { Tenant.count }, +1 do
      post platform_tenants_path, params: kitchen_payload(slug: slug, name: "Prep Kitchen #{slug}")
    end

    assert_response :redirect

    kitchen = Tenant.find_by!(slug: slug)
    assert_equal @org.id, kitchen.organization_id
    assert kitchen.production_kitchen?
    assert FeatureFlag.find_by!(tenant_id: kitchen.id, module: "prep_kitchen").enabled
    assert_not FeatureFlag.find_by!(tenant_id: kitchen.id, module: "barista").enabled
    assert_not FeatureFlag.find_by!(tenant_id: kitchen.id, module: "menu").enabled
    assert_not FeatureFlag.find_by!(tenant_id: kitchen.id, module: "kiosk").enabled
  end

  test "prep kitchen staff created via manager opens prep_kitchen panel after login" do
    slug = "onboard-pk-flow-#{SecureRandom.hex(4)}"
    post platform_tenants_path, params: kitchen_payload(slug: slug, name: "Kitchen Flow")
    kitchen = Tenant.find_by!(slug: slug)

    post open_as_manager_platform_tenant_path(kitchen)
    assert_redirected_to manager_dashboard_path
    assert_equal kitchen.id.to_s, session[:manager_tenant_id]

    email = "pk-mgr-#{SecureRandom.hex(4)}@test.local"
    assert_difference -> { User.count }, +1 do
      post manager_staff_members_path, params: {
        user: { name: "PK Manager", email: email, password: "pass123456" },
        role_codes: %w[prep_kitchen_manager]
      }
    end
    assert_redirected_to manager_staff_members_path

    pk_user = User.find_by!(email: email)
    assert pk_user.has_role?("prep_kitchen_manager")
    assert_equal kitchen.id, pk_user.tenant_id

    delete logout_path
    assert_redirected_to login_path

    post "/login", params: { email: email, password: "pass123456" }
    assert_redirected_to prep_kitchen_dashboard_path
    follow_redirect!

    get prep_kitchen_dashboard_path
    assert_response :success
    get prep_kitchen_inventory_path
    assert_response :success
  end

  private

  def kitchen_payload(slug:, name:)
    {
      tenant: {
        organization_id: @org.id,
        name: name,
        slug: slug,
        type: "production_kitchen",
        status: "active",
        city: "Kitchen City",
        address: "Industrial 1",
        country: "RU",
        currency: "RUB",
        timezone: "Europe/Moscow"
      },
      modules: {
        "prep_kitchen" => "1",
        "barista" => "0",
        "menu" => "0",
        "kiosk" => "0",
        "qr_offers" => "0",
        "tv_board" => "0"
      }
    }
  end
end
