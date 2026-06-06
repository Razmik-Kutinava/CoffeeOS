# frozen_string_literal: true

require "test_helper"

class Auth::SessionTrackerTest < ActiveSupport::TestCase
  setup do
    @tenant = create_tenant!
    @user = create_user!(tenant: @tenant, role_codes: %w[barista])
  end

  test "start! creates active session and stores id in rack session" do
    rack = {}
    request = OpenStruct.new(remote_ip: "127.0.0.1", user_agent: "TestAgent")

    assert_difference -> { Session.active.count }, 1 do
      Auth::SessionTracker.start!(
        user: @user,
        rack_session: rack,
        request: request,
        context_tenant_id: @tenant.id
      )
    end

    assert rack[:db_session_id].present?
    db_session = Session.find(rack[:db_session_id])
    assert_equal @user.id, db_session.user_id
    assert_equal @tenant.id, db_session.tenant_id
    assert db_session.active?
  end

  test "end! revokes session" do
    rack = {}
    request = OpenStruct.new(remote_ip: "127.0.0.1", user_agent: "TestAgent")
    Auth::SessionTracker.start!(
      user: @user,
      rack_session: rack,
      request: request,
      context_tenant_id: @tenant.id
    )
    sid = rack[:db_session_id]

    Auth::SessionTracker.end!(rack_session: rack)

    assert_nil rack[:db_session_id]
    refute Session.find(sid).active?
  end
end
