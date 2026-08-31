# frozen_string_literal: true

require "test_helper"

class Manager::DevicesTokenLifecycleTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @tenant = create_tenant!
    @gm = create_user!(
      tenant: @tenant,
      role_codes: %w[general_manager],
      email: "gm-dev-#{SecureRandom.hex(3)}@test.local"
    )
    @device = Device.create!(
      tenant: @tenant,
      name: "Test Kiosk",
      device_type: "kiosk",
      device_token: SecureRandom.hex(24),
      is_active: true
    )
    login_as!(@gm)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "revoke deactivates device and auth fails" do
    old_token = @device.device_token

    patch manager_device_revoke_path(@device)
    assert_redirected_to manager_devices_path

    post "/kiosk/api/auth", headers: { "X-Device-Token" => old_token }
    assert_response :unauthorized
  end

  test "rotate_token issues new token and invalidates old" do
    old_token = @device.device_token

    patch manager_device_rotate_token_path(@device)
    assert_redirected_to manager_devices_path

    @device.reload
    assert_not_equal old_token, @device.device_token

    post "/kiosk/api/auth", headers: { "X-Device-Token" => old_token }
    assert_response :unauthorized

    post "/kiosk/api/auth", headers: { "X-Device-Token" => @device.device_token }
    assert_response :success
  end

  test "rotate_token reactivates revoked device" do
    patch manager_device_revoke_path(@device)
    assert_redirected_to manager_devices_path
    @device.reload
    assert_not @device.is_active?

    patch manager_device_rotate_token_path(@device)
    assert_redirected_to manager_devices_path

    @device.reload
    assert @device.is_active?

    post "/kiosk/api/auth", headers: { "X-Device-Token" => @device.device_token }
    assert_response :success
  end
end
