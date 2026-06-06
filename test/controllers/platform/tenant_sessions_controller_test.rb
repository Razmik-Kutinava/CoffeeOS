# frozen_string_literal: true

require "test_helper"

class Platform::TenantSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    org = create_organization!
    anchor = create_tenant!(organization: org, slug: "sess-anchor-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: anchor,
      organization: org,
      role_codes: %w[ук_global_admin],
      email: "uk-sess-#{SecureRandom.hex(3)}@test.local",
      password: "pass123"
    )
    @tenant = create_tenant!(organization: org, name: "Sessions Point", slug: "sess-t-#{SecureRandom.hex(3)}")
    @barista = create_user!(
      tenant: @tenant,
      role_codes: %w[barista],
      email: "barista-sess-#{SecureRandom.hex(3)}@test.local",
      password: "pass123",
      name: "Barista One"
    )
  end

  test "redirects guest to login" do
    get platform_monitoring_tenant_sessions_path(@tenant)
    assert_redirected_to login_path
  end

  test "uk admin sees tenant sessions page" do
    login_as!(@uk)
    get platform_monitoring_tenant_sessions_path(@tenant)
    assert_response :success
    assert_includes response.body, "Сессии"
    assert_includes response.body, @tenant.name
    assert_includes response.body, "Barista One"
    assert_includes response.body, "Сводка ролей"
    assert_includes response.body, "▸ JSON"
  end

  test "uk admin gets sessions json" do
    login_as!(@uk)
    get platform_monitoring_tenant_sessions_path(@tenant, format: :json)
    assert_response :success
    data = JSON.parse(response.body)
    assert_equal @tenant.id, data.dig("tenant", "id")
    assert data.key?("users")
    assert data.key?("active_sessions")
    assert data.key?("roles_summary")
    assert data.key?("recent_events")
  end

  test "shows active session after barista login" do
    post "/login", params: { email: @barista.email, password: "pass123" }
    assert_response :redirect

    login_as!(@uk)
    get platform_monitoring_tenant_sessions_path(@tenant)
    assert_response :success
    assert_includes response.body, "ОНЛАЙН"
    assert_includes response.body, @barista.email
  end
end
