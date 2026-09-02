# frozen_string_literal: true

require "test_helper"

class Platform::UkSinglePointDashboardTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @org = create_organization!(slug: "uk-dash-org-#{SecureRandom.hex(3)}")
    @point_a = create_tenant!(
      slug: Platform::SinglePointMode::POINT_A_SLUG,
      name: "Demo Coffee Point A",
      organization: @org
    )
    @junk = create_tenant!(
      slug: "uk-dash-junk-#{SecureRandom.hex(4)}",
      name: "Fly Overnight Junk",
      organization: @org,
      status: "inactive"
    )
    @other_active = create_tenant!(
      slug: "uk-dash-other-#{SecureRandom.hex(4)}",
      name: "Other Active",
      organization: @org,
      status: "active"
    )
    @uk = create_user!(
      tenant: @point_a,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-dash-#{SecureRandom.hex(4)}@test.local",
      password: "pass123"
    )
    login_as!(@uk)
  end

  test "dashboard in single point mode shows only point a" do
    old = ENV["DEMO_SINGLE_POINT"]
    ENV["DEMO_SINGLE_POINT"] = "true"

    get platform_root_path

    assert_response :success
    assert_includes response.body, "Demo Coffee Point A"
    assert_not_includes response.body, "Fly Overnight Junk"
    assert_not_includes response.body, "Other Active"
    assert_not_includes response.body, "Новая точка"
  ensure
    old.nil? ? ENV.delete("DEMO_SINGLE_POINT") : ENV["DEMO_SINGLE_POINT"] = old
  end
end
