# frozen_string_literal: true

require "test_helper"

class OrdersChannelTest < ActionCable::Channel::TestCase
  include TestFactories

  tests OrdersChannel

  setup do
    @tenant = create_tenant!
    @user = create_user!(tenant: @tenant, role_codes: %w[barista], email: "orders-ch-#{SecureRandom.hex(3)}@test.local")
  end

  test "subscribes for staff user from connection current_user" do
    stub_connection(current_user: @user)

    subscribe

    assert subscription.confirmed?
    assert_has_stream "orders_#{@tenant.id}"
  end

  test "subscribes for tv board device actor" do
    device = Device.create!(
      tenant: @tenant,
      device_type: "tv_board",
      name: "TV stream",
      device_token: SecureRandom.hex(24),
      is_active: true
    )
    stub_connection(current_user: device)

    subscribe

    assert subscription.confirmed?
    assert_has_stream "orders_#{@tenant.id}"
  end

  test "rejects without connection actor" do
    stub_connection(current_user: nil)

    subscribe

    assert subscription.rejected?
  end
end
