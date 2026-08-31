# frozen_string_literal: true

require "test_helper"

class Manager::DevicesTokenTtlUiTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false
    @ttl_prev = ENV["DEVICE_TOKEN_TTL_DAYS"]

    @tenant = create_tenant!
    @gm = create_user!(
      tenant: @tenant,
      role_codes: %w[general_manager],
      email: "gm-ttl-#{SecureRandom.hex(3)}@test.local"
    )
    @device = Device.create!(
      tenant: @tenant,
      name: "TTL Kiosk",
      device_type: "kiosk",
      device_token: SecureRandom.hex(24),
      is_active: true,
      token_expires_at: 5.days.from_now
    )
    login_as!(@gm)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
    ENV["DEVICE_TOKEN_TTL_DAYS"] = @ttl_prev
  end

  test "devices index shows ttl policy and expiry label" do
    ENV["DEVICE_TOKEN_TTL_DAYS"] = "90"

    get manager_devices_path
    assert_response :success
    assert_match "DEVICE_TOKEN_TTL_DAYS=90", response.body
    assert_match "5 дн.", response.body
  end
end
