# frozen_string_literal: true

require "test_helper"

# В2 CHECKLIST §B — /health/tenants отражает активные точки.
class Health::TenantsControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    org = create_organization!
    anchor = create_tenant!(organization: org, slug: "health-anchor-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: anchor,
      organization: org,
      role_codes: %w[ук_global_admin],
      email: "uk-health-#{SecureRandom.hex(3)}@test.local",
      password: "pass123"
    )
    @tenant = create_tenant!(organization: org, name: "Health Tenant", slug: "health-t-#{SecureRandom.hex(3)}")
  end

  test "returns 401 without auth" do
    get "/health/tenants"
    assert_response :unauthorized
  end

  test "uk_global_admin gets JSON with tenants list" do
    login_as!(@uk)
    get "/health/tenants"
    assert_response :success
    data = JSON.parse(response.body)
    assert data.key?("tenants")
    assert data.key?("generated_at")
    ids = data["tenants"].map { |t| t["id"] }
    assert_includes ids, @tenant.id
  end

  test "health show returns checks for tenant" do
    login_as!(@uk)
    get "/health/tenants/#{@tenant.id}"
    assert_response :success
    data = JSON.parse(response.body)
    assert data.key?("checks")
    assert data.key?("overall")
    assert data.key?("check_details")
    assert data.key?("unified_feed")
  end

  test "health events returns feed json" do
    login_as!(@uk)
    get "/health/tenants/#{@tenant.id}/events"
    assert_response :success
    data = JSON.parse(response.body)
    assert data.key?("check_details")
    assert data.key?("unified_feed")
  end
end
