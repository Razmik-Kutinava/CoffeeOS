# frozen_string_literal: true

require "test_helper"
require_relative "../../support/rls_test_bootstrap"

class Rls::DeviceTokenLookupTest < ActiveSupport::TestCase
  include TestFactories

  self.use_transactional_tests = false

  setup do
    @tenant_a = create_tenant!(slug: "dev-rls-a-#{SecureRandom.hex(3)}")
    @tenant_b = create_tenant!(slug: "dev-rls-b-#{SecureRandom.hex(3)}")
    @token = "shared-lookup-#{SecureRandom.hex(8)}"
    @device_a = Device.create!(
      tenant: @tenant_a,
      name: "Kiosk A",
      device_type: "kiosk",
      device_token: @token,
      is_active: true
    )
    enable_devices_rls!
  end

  teardown do
    disable_devices_rls!
    @device_a&.destroy
    @tenant_a&.destroy
    @tenant_b&.destroy
  end

  test "device token lookup blocked without GUC under RLS" do
    conn = ActiveRecord::Base.connection
    conn.execute("SET ROLE #{quote_role(conn)}")
    found = conn.transaction do
      conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(@tenant_b.id.to_s)}")
      Device.find_by(device_token: @token, device_type: "kiosk", is_active: true)
    end
    assert_nil found
  ensure
    conn.execute("RESET ROLE") rescue nil
  end

  test "device token lookup works with app.device_token_lookup GUC" do
    found = Devices::TokenResolver.find_active(token: @token, device_type: "kiosk")
    assert_equal @device_a.id, found.id
  end

  test "revoked device not returned by resolver" do
    @device_a.update!(is_active: false)
    assert_nil Devices::TokenResolver.find_active(token: @token, device_type: "kiosk")
  end

  private

  def enable_devices_rls!
    conn = ActiveRecord::Base.connection
    conn.execute("ALTER TABLE devices ENABLE ROW LEVEL SECURITY")
    conn.execute("ALTER TABLE devices FORCE ROW LEVEL SECURITY")
    ensure_token_lookup_policy!(conn)
    ensure_test_role!(conn)
  end

  def disable_devices_rls!
    conn = ActiveRecord::Base.connection
    conn.execute("ALTER TABLE devices DISABLE ROW LEVEL SECURITY")
    conn.execute("RESET ROLE") rescue nil
  end

  def ensure_token_lookup_policy!(conn)
    RlsTestBootstrap.apply_devices_token_lookup_policy!(conn)
  end

  def ensure_test_role!(conn)
    RlsTestBootstrap.ensure_test_role!(conn)
  end

  def quote_role(conn)
    RlsTestBootstrap::TEST_ROLE
  end
end
