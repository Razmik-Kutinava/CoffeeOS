# frozen_string_literal: true

require "test_helper"

class Devices::TokenRotationTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @device = Device.create!(
      tenant: @tenant,
      name: "Kiosk",
      device_type: "kiosk",
      device_token: SecureRandom.hex(24),
      is_active: true
    )
  end

  test "call! rotates token on active device" do
    old = @device.device_token
    new_token = Devices::TokenRotation.call!(device: @device)
    assert_not_equal old, new_token
    assert_equal new_token, @device.reload.device_token
  end

  test "call! reactivates revoked device with new token" do
    @device.update!(is_active: false)
    new_token = Devices::TokenRotation.call!(device: @device)
    @device.reload
    assert @device.is_active?
    assert_equal new_token, @device.device_token
  end
end
