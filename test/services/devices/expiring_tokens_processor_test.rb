# frozen_string_literal: true

require "test_helper"

class Devices::ExpiringTokensProcessorTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    @ttl_prev = ENV["DEVICE_TOKEN_TTL_DAYS"]
    @warn_prev = ENV["DEVICE_TOKEN_ROTATE_WARN_DAYS"]
    ENV["DEVICE_TOKEN_TTL_DAYS"] = "90"
    ENV["DEVICE_TOKEN_ROTATE_WARN_DAYS"] = "14"

    @tenant = create_tenant!
    @now = Time.zone.parse("2026-08-31 12:00:00")
  end

  teardown do
    ENV["DEVICE_TOKEN_TTL_DAYS"] = @ttl_prev
    ENV["DEVICE_TOKEN_ROTATE_WARN_DAYS"] = @warn_prev
  end

  test "skips when DEVICE_TOKEN_TTL_DAYS not configured" do
    ENV.delete("DEVICE_TOKEN_TTL_DAYS")

    result = Devices::ExpiringTokensProcessor.call(now: @now)

    assert result.skipped_ttl
    assert_equal 0, result.deactivated
  end

  test "deactivates expired active device and enqueues alert" do
    device = Device.create!(
      tenant: @tenant,
      name: "Expired Kiosk",
      device_type: "kiosk",
      device_token: SecureRandom.hex(24),
      is_active: true,
      token_expires_at: @now - 1.hour
    )

    assert_enqueued_with(job: TelegramAlertJob) do
      result = Devices::ExpiringTokensProcessor.call(now: @now)
      assert_equal 1, result.deactivated
    end

    device.reload
    assert_not device.is_active?
    assert_equal "cron", device.metadata["token_expiry_deactivated_by"]
  end

  test "warns on expiring soon without deactivating" do
    device = Device.create!(
      tenant: @tenant,
      name: "Soon TV",
      device_type: "tv_board",
      device_token: SecureRandom.hex(24),
      is_active: true,
      token_expires_at: @now + 5.days
    )

    assert_enqueued_with(job: TelegramAlertJob) do
      result = Devices::ExpiringTokensProcessor.call(now: @now)
      assert_equal 1, result.warned
      assert_equal 0, result.deactivated
    end

    assert device.reload.is_active?
    assert device.metadata["token_expiry_warned_at"].present?
  end

  test "does not re-warn within 7 days" do
    Device.create!(
      tenant: @tenant,
      name: "Warned Kiosk",
      device_type: "kiosk",
      device_token: SecureRandom.hex(24),
      is_active: true,
      token_expires_at: @now + 5.days,
      metadata: { "token_expiry_warned_at" => (@now - 2.days).iso8601 }
    )

    assert_no_enqueued_jobs(only: TelegramAlertJob) do
      result = Devices::ExpiringTokensProcessor.call(now: @now)
      assert_equal 0, result.warned
    end
  end

  test "rotate clears cron metadata" do
    device = Device.create!(
      tenant: @tenant,
      name: "Rotate Me",
      device_type: "kiosk",
      device_token: SecureRandom.hex(24),
      is_active: false,
      token_expires_at: @now - 1.day,
      metadata: {
        "token_expiry_deactivated_at" => @now.iso8601,
        "token_expiry_deactivated_by" => "cron"
      }
    )

    Devices::TokenRotation.call!(device: device)

    device.reload
    assert device.is_active?
    assert_nil device.metadata["token_expiry_deactivated_at"]
  end
end
