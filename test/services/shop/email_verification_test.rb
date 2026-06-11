# frozen_string_literal: true

require "test_helper"

class Shop::EmailVerificationTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @email = "verify-db-#{SecureRandom.hex(4)}@example.com"
    @session = {}
    @session_id = SecureRandom.hex(16)
  end

  test "mark_verified persists to session and database" do
    Shop::EmailVerification.mark_verified!(
      session: @session,
      tenant_id: @tenant.id,
      email: @email,
      session_id: @session_id
    )

    assert_equal @email, Shop::EmailVerificationSession.verified_email(@session, @tenant.id)
    record = ShopEmailVerification.active_for(tenant_id: @tenant.id, session_id: @session_id)
    assert_equal @email, record.email
  end

  test "verified_email reads from database when session bucket empty" do
    Shop::EmailVerification.mark_verified!(
      session: @session,
      tenant_id: @tenant.id,
      email: @email,
      session_id: @session_id
    )
    @session.clear

    email = Shop::EmailVerification.verified_email(
      session: @session,
      tenant_id: @tenant.id,
      session_id: @session_id
    )
    assert_equal @email, email
  end

  test "verification isolated per tenant" do
    other = create_tenant!(slug: "verify-other-#{SecureRandom.hex(3)}")

    Shop::EmailVerification.mark_verified!(
      session: @session,
      tenant_id: @tenant.id,
      email: @email,
      session_id: @session_id
    )
    @session.clear

    refute Shop::EmailVerification.verified_email(
      session: @session,
      tenant_id: other.id,
      session_id: @session_id
    )
  end

  test "expired database record is ignored" do
    ShopEmailVerification.upsert_verified!(
      tenant_id: @tenant.id,
      session_id: @session_id,
      email: @email,
      expires_at: 1.minute.ago
    )

    refute Shop::EmailVerification.verified_email(
      session: @session,
      tenant_id: @tenant.id,
      session_id: @session_id
    )
  end
end
