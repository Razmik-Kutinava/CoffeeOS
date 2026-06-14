# frozen_string_literal: true

require "test_helper"

class Shop::EmailVerificationTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @email = "verify-db-#{SecureRandom.hex(4)}@example.com"
    @session = {}
  end

  test "mark_verified persists to session and database by tenant and email" do
    Shop::EmailVerification.mark_verified!(
      session: @session,
      tenant_id: @tenant.id,
      email: @email
    )

    assert_equal @email, Shop::EmailVerificationSession.verified_email(@session, @tenant.id)
    record = ShopEmailVerification.active_for(tenant_id: @tenant.id, email: @email)
    assert_equal @email, record.email
  end

  test "verified_email reads from database when session bucket empty" do
    Shop::EmailVerification.mark_verified!(
      session: @session,
      tenant_id: @tenant.id,
      email: @email
    )
    @session.clear

    email = Shop::EmailVerification.verified_email(
      session: @session,
      tenant_id: @tenant.id,
      email: @email
    )
    assert_equal @email, email
  end

  test "verification isolated per tenant" do
    other = create_tenant!(slug: "verify-other-#{SecureRandom.hex(3)}")

    Shop::EmailVerification.mark_verified!(
      session: @session,
      tenant_id: @tenant.id,
      email: @email
    )
    @session.clear

    refute Shop::EmailVerification.verified_email(
      session: @session,
      tenant_id: other.id,
      email: @email
    )
  end

  test "verified_email works across browser sessions when email is known" do
    Shop::EmailVerification.mark_verified!(
      session: @session,
      tenant_id: @tenant.id,
      email: @email
    )
    fresh_session = {}

    email = Shop::EmailVerification.verified_email(
      session: fresh_session,
      tenant_id: @tenant.id,
      email: @email
    )

    assert_equal @email, email
    assert_equal @email, Shop::EmailVerificationSession.verified_email(fresh_session, @tenant.id)
  end

  test "expired database record is ignored" do
    ShopEmailVerification.upsert_verified!(
      tenant_id: @tenant.id,
      email: @email,
      expires_at: 1.minute.ago
    )

    refute Shop::EmailVerification.verified_email(
      session: @session,
      tenant_id: @tenant.id,
      email: @email
    )
  end

  test "mark_verified extends expiry for same tenant and email" do
    ShopEmailVerification.upsert_verified!(
      tenant_id: @tenant.id,
      email: @email,
      expires_at: 1.hour.from_now
    )

    Shop::EmailVerification.mark_verified!(
      session: @session,
      tenant_id: @tenant.id,
      email: @email
    )

    assert_equal 1, ShopEmailVerification.where(tenant_id: @tenant.id, email: @email).count
    record = ShopEmailVerification.active_for(tenant_id: @tenant.id, email: @email)
    assert record.expires_at > 2.hours.from_now
  end
end
