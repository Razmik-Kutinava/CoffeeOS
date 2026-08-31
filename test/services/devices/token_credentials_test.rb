# frozen_string_literal: true

require "test_helper"

class Devices::TokenCredentialsTest < ActiveSupport::TestCase
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
    @ttl_prev = ENV["DEVICE_TOKEN_TTL_DAYS"]
  end

  teardown do
    ENV["DEVICE_TOKEN_TTL_DAYS"] = @ttl_prev
  end

  test "default_expires_at is nil when env unset" do
    ENV.delete("DEVICE_TOKEN_TTL_DAYS")
    assert_nil Devices::TokenCredentials.default_expires_at
  end

  test "default_expires_at uses DEVICE_TOKEN_TTL_DAYS" do
    ENV["DEVICE_TOKEN_TTL_DAYS"] = "90"
    travel_to Time.zone.parse("2026-08-31 12:00:00") do
      expires = Devices::TokenCredentials.default_expires_at
      assert_in_delta 90.days.from_now.to_i, expires.to_i, 2
    end
  end

  test "assign_new! rotates token and can reactivate revoked device" do
    old = @device.device_token
    @device.update!(is_active: false)

    new_token = Devices::TokenCredentials.assign_new!(device: @device)

    @device.reload
    assert_not_equal old, new_token
    assert @device.is_active?
    assert_equal new_token, @device.device_token
  end
end
