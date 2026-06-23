# frozen_string_literal: true

require "test_helper"

# B1.14: карта координат точки в форме УК.
class Platform::B114TenantMapTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @org = create_organization!(slug: "b114-map-org-#{SecureRandom.hex(3)}")
    anchor = create_tenant!(organization: @org, slug: "b114-map-anchor-#{SecureRandom.hex(4)}")
    @uk = create_user!(
      tenant: anchor,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-map-#{SecureRandom.hex(3)}@test.local",
      password: "pass123"
    )
    login_as!(@uk)
    @tenant = create_tenant!(
      organization: @org,
      slug: "b114-map-point-#{SecureRandom.hex(4)}",
      name: "Map Point",
      city: "Москва",
      address: "ул. Тестовая, 1"
    )
  end

  test "edit form includes tenant map stimulus block for sales_point" do
    get edit_platform_tenant_path(@tenant)
    assert_response :success
    assert_select "[data-controller='tenant-map']"
    assert_select "input[name='tenant[latitude]']"
    assert_select "input[name='tenant[longitude]']"
    assert_select "[data-testid='tenant-map-canvas']"
    assert_includes response.body, "leaflet-src.esm.js"
  end

  test "uk updates tenant latitude and longitude" do
    patch platform_tenant_path(@tenant), params: {
      tenant: {
        organization_id: @org.id,
        name: @tenant.name,
        slug: @tenant.slug,
        type: "sales_point",
        status: "active",
        city: "Москва",
        address: "ул. Тестовая, 1",
        latitude: 55.7568,
        longitude: 37.6158,
        country: "RU",
        currency: "RUB",
        timezone: "Europe/Moscow"
      },
      weekday_schedules: {
        "0" => { enabled: "1", opens_at: "09:00", closes_at: "18:00" }
      },
      modules: { "menu" => "1", "barista" => "1" }
    }

    assert_redirected_to platform_tenant_path(@tenant)
    @tenant.reload
    assert_in_delta 55.7568, @tenant.latitude.to_f, 0.0001
    assert_in_delta 37.6158, @tenant.longitude.to_f, 0.0001

    get platform_tenant_path(@tenant)
    assert_response :success
    assert_includes response.body, "55.7568"
    assert_includes response.body, "37.6158"
  end
end
