# frozen_string_literal: true

require "test_helper"

class Platform::MonitoringControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    org = create_organization!
    anchor = create_tenant!(organization: org, slug: "mon-anchor-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: anchor,
      organization: org,
      role_codes: %w[ук_global_admin],
      email: "uk-mon-#{SecureRandom.hex(3)}@test.local",
      password: "pass123"
    )
    @tenant = create_tenant!(organization: org, name: "Monitor Point", slug: "mon-t-#{SecureRandom.hex(3)}")
  end

  test "redirects guest to login" do
    get platform_monitoring_path
    assert_redirected_to login_path
  end

  test "uk admin sees monitoring summary" do
    login_as!(@uk)
    get platform_monitoring_path
    assert_response :success
    assert_includes response.body, "Мониторинг точек"
    assert_includes response.body, @tenant.name
  end

  test "uk admin sees tenant drill-down" do
    login_as!(@uk)
    get platform_monitoring_tenant_path(@tenant)
    assert_response :success
    assert_includes response.body, @tenant.name
    assert_includes response.body, "Проверки и детали"
    assert_includes response.body, "Единая лента"
  end

  test "uk admin gets events json" do
    login_as!(@uk)
    get platform_monitoring_tenant_events_path(@tenant)
    assert_response :success
    data = JSON.parse(response.body)
    assert data.key?("check_details")
    assert data.key?("unified_feed")
  end
end
