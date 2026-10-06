# frozen_string_literal: true

require "test_helper"

# ТВ-табло точки создаётся и отключается прямо из карточки точки в УК.
class Platform::TenantDevicesControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @point = create_tenant!(slug: "tv-uk-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: @point,
      role_codes: %w[ук_global_admin],
      email: "uk-tv-#{SecureRandom.hex(4)}@test.local"
    )
    login_as!(@uk)
  end

  def tv_devices
    Device.where(tenant_id: @point.id, device_type: "tv_board")
  end

  test "creates tv for point and shows its link" do
    assert_difference -> { tv_devices.count }, +1 do
      post platform_tenant_tv_devices_path(@point), params: { device: { name: "Зал" } }
    end
    assert_redirected_to platform_tenant_path(@point)

    device = tv_devices.last
    assert device.is_active
    assert_equal Device::TV_MODE_ORDERS, device.metadata["tv_mode"]

    follow_redirect!
    assert_includes response.body, "/tv_board?token=#{device.device_token}"
    assert_includes response.body, "Зал"
  end

  test "tv module off: tv is not created" do
    FeatureFlag.find_or_initialize_by(tenant_id: @point.id, module: "tv_board").update!(enabled: false)

    assert_no_difference -> { tv_devices.count } do
      post platform_tenant_tv_devices_path(@point), params: { device: { name: "Зал" } }
    end
    assert_redirected_to platform_tenant_path(@point)
  end

  test "revoke disables tv token" do
    post platform_tenant_tv_devices_path(@point), params: { device: { name: "Зал" } }
    device = tv_devices.last

    patch revoke_platform_tenant_tv_device_path(@point, device)

    assert_redirected_to platform_tenant_path(@point)
    assert_not device.reload.is_active
  end

  test "cannot revoke device of another point" do
    other = create_tenant!
    foreign = Device.create!(
      tenant: other, device_type: "tv_board", name: "чужой",
      device_token: SecureRandom.hex(8), is_active: true
    )

    patch revoke_platform_tenant_tv_device_path(@point, foreign)

    assert_response :not_found
    assert foreign.reload.is_active
  end
end
