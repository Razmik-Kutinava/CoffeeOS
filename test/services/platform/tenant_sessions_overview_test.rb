# frozen_string_literal: true

require "test_helper"

class Platform::TenantSessionsOverviewTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @user = create_user!(tenant: @tenant, role_codes: %w[barista], name: "Worker")
  end

  test "includes users roles and session events" do
    Auth::LoginJournal.record_login!(user: @user, role_code: "barista", context_tenant_id: @tenant.id)
    Session.create!(
      user: @user,
      tenant_id: @tenant.id,
      token: SecureRandom.urlsafe_base64(32),
      expires_at: 1.hour.from_now,
      ip_address: "10.0.0.1"
    )

    data = Platform::TenantSessionsOverview.new(@tenant).call

    assert_equal 1, data[:users_count]
    assert_equal 1, data[:active_sessions_count]
    assert_equal 1, data[:roles_summary]["barista"]
    assert_equal "Worker", data[:users].first[:name]
    assert data[:users].first[:online]
  end
end
