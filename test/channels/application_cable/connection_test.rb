# frozen_string_literal: true

require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  include TestFactories

  test "identifies staff user from session via auth_login path" do
    tenant = create_tenant!
    user = create_user!(tenant: tenant, role_codes: %w[barista], email: "cable-staff-#{SecureRandom.hex(3)}@test.local")

    connect session: { user_id: user.id }

    assert_instance_of User, connection.current_user
    assert_equal user.id, connection.current_user.id
  end

  test "identifies tv board device from tv_device_token cookie via TokenResolver" do
    tenant = create_tenant!
    device = Device.create!(
      tenant: tenant,
      device_type: "tv_board",
      name: "Cable TV",
      device_token: SecureRandom.hex(24),
      is_active: true
    )

    connect env: { "HTTP_COOKIE" => "tv_device_token=#{device.device_token}" }

    assert_instance_of Device, connection.current_user
    assert_equal device.id, connection.current_user.id
  end

  test "nil current_user for invalid tv device cookie" do
    connect env: { "HTTP_COOKIE" => "tv_device_token=not-a-valid-token" }

    assert_nil connection.current_user
  end

  test "nil current_user for revoked tv device cookie" do
    tenant = create_tenant!
    device = Device.create!(
      tenant: tenant,
      device_type: "tv_board",
      name: "Revoked TV",
      device_token: SecureRandom.hex(24),
      is_active: false
    )

    connect env: { "HTTP_COOKIE" => "tv_device_token=#{device.device_token}" }

    assert_nil connection.current_user
  end
end
