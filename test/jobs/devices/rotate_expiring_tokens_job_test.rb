# frozen_string_literal: true

require "test_helper"

class Devices::RotateExpiringTokensJobTest < ActiveJob::TestCase
  include TestFactories

  setup do
    @ttl_prev = ENV["DEVICE_TOKEN_TTL_DAYS"]
    ENV["DEVICE_TOKEN_TTL_DAYS"] = "90"
    @tenant = create_tenant!
  end

  teardown do
    ENV["DEVICE_TOKEN_TTL_DAYS"] = @ttl_prev
  end

  test "perform runs expiring tokens processor" do
    Device.create!(
      tenant: @tenant,
      name: "Job Expired",
      device_type: "kiosk",
      device_token: SecureRandom.hex(24),
      is_active: true,
      token_expires_at: 1.hour.ago
    )

    assert_enqueued_with(job: TelegramAlertJob) do
      Devices::RotateExpiringTokensJob.perform_now
    end
  end
end
