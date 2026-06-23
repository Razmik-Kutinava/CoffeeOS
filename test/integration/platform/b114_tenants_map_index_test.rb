# frozen_string_literal: true

require "test_helper"

class Platform::B114TenantsMapIndexTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @org = create_organization!(slug: "b114-idx-map-#{SecureRandom.hex(3)}")
    anchor = create_tenant!(organization: @org, slug: "b114-idx-anchor-#{SecureRandom.hex(4)}")
    @uk = create_user!(
      tenant: anchor,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-idx-map-#{SecureRandom.hex(3)}@test.local",
      password: "pass123"
    )
    login_as!(@uk)

    @mapped = create_tenant!(
      organization: @org,
      slug: "b114-idx-mapped-#{SecureRandom.hex(4)}",
      name: "Mapped Point",
      city: "Москва",
      address: "ул. Карты, 1",
      latitude: 55.7568,
      longitude: 37.6158
    )
    create_tenant!(
      organization: @org,
      slug: "b114-idx-plain-#{SecureRandom.hex(4)}",
      name: "Plain Point",
      city: "Москва",
      address: "без координат"
    )
  end

  test "tenants index includes map block with pins json" do
    get platform_tenants_path
    assert_response :success
    assert_select "[data-testid='tenants-index-map']"
    assert_select "[data-controller='tenants-map']"
    assert_includes response.body, @mapped.name
    assert_includes response.body, "55.7568"
    assert_includes response.body, "37.6158"
    assert_includes response.body, platform_tenant_path(@mapped)
  end
end
