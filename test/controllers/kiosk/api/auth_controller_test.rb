# frozen_string_literal: true

require "test_helper"

class Kiosk::Api::AuthControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "kiosk-auth-#{SecureRandom.hex(3)}")
    @device = Device.create!(
      tenant: @tenant,
      device_type: "kiosk",
      name: "Front kiosk",
      device_token: SecureRandom.hex(24),
      is_active: true
    )
  end

  test "returns tenant for valid device token in header" do
    post "/kiosk/api/auth", headers: { "X-Device-Token" => @device.device_token }

    assert_response :success
    body = response.parsed_body
    assert_equal @tenant.id, body["tenant_id"]
    assert_equal @tenant.name, body["tenant_name"]
    assert_equal @device.id, body["device_id"]
    assert body["kiosk_settings"].is_a?(Hash)
  end

  test "returns tenant for valid device token in params" do
    post "/kiosk/api/auth", params: { device_token: @device.device_token }

    assert_response :success
    assert_equal @tenant.id, response.parsed_body["tenant_id"]
  end

  test "returns unauthorized for missing token" do
    post "/kiosk/api/auth"
    assert_response :unauthorized
  end

  test "returns unauthorized for wrong token" do
    post "/kiosk/api/auth", headers: { "X-Device-Token" => "bad-token" }
    assert_response :unauthorized
  end

  test "returns unauthorized for inactive kiosk" do
    @device.update!(is_active: false)
    post "/kiosk/api/auth", headers: { "X-Device-Token" => @device.device_token }
    assert_response :unauthorized
  end

  test "returns unauthorized for expired token" do
    @device.update!(token_expires_at: 1.hour.ago)
    post "/kiosk/api/auth", headers: { "X-Device-Token" => @device.device_token }
    assert_response :unauthorized
  end

  test "returns persisted kiosk_settings under tenant GUC" do
    KioskSetting.create!(
      tenant: @tenant,
      device: @device,
      allow_card: false,
      allow_cash: true,
      idle_timeout_seconds: 120,
      welcome_text: "CR05 kiosk welcome",
      is_active: true
    )

    post "/kiosk/api/auth", headers: { "X-Device-Token" => @device.device_token }

    assert_response :success
    settings = response.parsed_body["kiosk_settings"]
    assert_equal "CR05 kiosk welcome", settings["welcome_text"]
    assert_equal false, settings["allow_card"]
    assert_equal true, settings["allow_cash"]
    assert_equal 120, settings["idle_timeout_seconds"]
  end

  test "returns unauthorized for tv_board token" do
    tv = Device.create!(
      tenant: @tenant,
      device_type: "tv_board",
      name: "TV",
      device_token: SecureRandom.hex(24),
      is_active: true
    )
    post "/kiosk/api/auth", headers: { "X-Device-Token" => tv.device_token }
    assert_response :unauthorized
  end
end
