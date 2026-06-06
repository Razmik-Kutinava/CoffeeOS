# frozen_string_literal: true

require "test_helper"

class Auth::LoginJournalTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "login-journal-#{SecureRandom.hex(3)}")
    @user = create_user!(
      tenant: @tenant,
      role_codes: %w[ук_global_admin],
      email: "journal-#{SecureRandom.hex(3)}@test.local"
    )
  end

  test "record_login creates admin audit log" do
    assert_difference -> { AdminAuditLog.where(action: Auth::LoginJournal::ACTION_LOGIN).count }, 1 do
      Auth::LoginJournal.record_login!(user: @user, role_code: "ук_global_admin")
    end

    log = AdminAuditLog.order(created_at: :desc).first
    assert_equal @user.id, log.actor_id
    assert_equal @user.id, log.details["user_id"]
    assert_equal @user.email, log.details["email"]
  end

  test "record_logout creates admin audit log" do
    assert_difference -> { AdminAuditLog.where(action: Auth::LoginJournal::ACTION_LOGOUT).count }, 1 do
      Auth::LoginJournal.record_logout!(user: @user, role_code: "ук_global_admin")
    end
  end
end
