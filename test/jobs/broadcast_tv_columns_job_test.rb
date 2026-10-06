# frozen_string_literal: true

require "test_helper"

class BroadcastTvColumnsJobTest < ActiveJob::TestCase
  include TestFactories
  include ActionCable::TestHelper

  setup do
    @tenant = create_tenant!
    @device = Device.create!(
      tenant: @tenant,
      device_type: "tv_board",
      name: "tv-#{SecureRandom.hex(3)}",
      device_token: SecureRandom.hex(8),
      is_active: true,
      metadata: { "tv_mode" => Device::TV_MODE_ORDERS }
    )
    @stream = "tv_orders_#{@device.id}"
  end

  test "broadcasts columns to active tv when module is on" do
    BroadcastTvColumnsJob.perform_now(@tenant.id)

    assert_broadcasts @stream, 4
  end

  test "tv_board module off: nothing is broadcast to open tv screens" do
    FeatureFlag.find_or_initialize_by(tenant_id: @tenant.id, module: "tv_board").update!(enabled: false)

    BroadcastTvColumnsJob.perform_now(@tenant.id)

    assert_broadcasts @stream, 0
  end
end
