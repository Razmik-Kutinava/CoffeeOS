# frozen_string_literal: true

require "test_helper"

class Platform::UkSinglePointDashboardTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @org = create_organization!(name: "Тестовая франшиза", slug: "uk-dash-org-#{SecureRandom.hex(3)}")
    @point_a = create_tenant!(
      slug: Platform::SinglePointMode::POINT_A_SLUG,
      name: "Витрина А",
      organization: @org
    )
    @inactive = create_tenant!(
      slug: "uk-dash-inactive-#{SecureRandom.hex(4)}",
      name: "Закрытая точка",
      organization: @org,
      status: "inactive"
    )
    @kitchen = create_prep_kitchen_tenant!(name: "Цех франшизы", organization: @org)
    @uk = create_user!(
      tenant: @point_a,
      organization: nil,
      role_codes: %w[ук_global_admin],
      email: "uk-dash-#{SecureRandom.hex(4)}@test.local",
      password: "pass123"
    )
    login_as!(@uk)
  end

  test "dashboard shows all points of all organizations and Code Black brand" do
    old = ENV["DEMO_SINGLE_POINT"]
    ENV["DEMO_SINGLE_POINT"] = "true"

    get platform_root_path

    assert_response :success
    assert_includes response.body, "Code Black"
    assert_includes response.body, "Витрина А"
    assert_includes response.body, "Закрытая точка"
    assert_includes response.body, "Цех франшизы"
    assert_includes response.body, "Тестовая франшиза"
    assert_includes response.body, "Новая точка"
  ensure
    old.nil? ? ENV.delete("DEMO_SINGLE_POINT") : ENV["DEMO_SINGLE_POINT"] = old
  end

  test "tenants index shows type and status, and new point link" do
    get platform_tenants_path

    assert_response :success
    assert_includes response.body, "Цех франшизы"
    assert_includes response.body, "Закрытая точка"
    assert_includes response.body, "Цех"
    assert_includes response.body, "неактивна"
    assert_includes response.body, new_platform_tenant_path
  end

  test "organizations index shows organizations without points and new link" do
    empty = create_organization!(name: "Пустая франшиза", slug: "uk-dash-empty-#{SecureRandom.hex(3)}")

    get platform_organizations_path

    assert_response :success
    assert_includes response.body, empty.name
    assert_includes response.body, new_platform_organization_path
  end
end
