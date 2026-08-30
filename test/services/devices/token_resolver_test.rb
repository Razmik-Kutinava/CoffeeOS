# frozen_string_literal: true

require "test_helper"

class Devices::TokenResolverTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @device = Device.create!(
      tenant: @tenant,
      name: "Kiosk A",
      device_type: "kiosk",
      device_token: "kiosk-token-#{SecureRandom.hex(4)}",
      is_active: true
    )
  end

  test "find_active returns device for valid kiosk token" do
    found = Devices::TokenResolver.find_active(token: @device.device_token, device_type: "kiosk")
    assert_equal @device.id, found.id
  end

  test "find_active returns nil for wrong device type" do
    assert_nil Devices::TokenResolver.find_active(token: @device.device_token, device_type: "tv_board")
  end

  test "find_active returns nil for unknown token" do
    assert_nil Devices::TokenResolver.find_active(token: "missing", device_type: "kiosk")
  end

  test "find_active returns nil when device inactive" do
    @device.update!(is_active: false)
    assert_nil Devices::TokenResolver.find_active(token: @device.device_token, device_type: "kiosk")
  end
end
