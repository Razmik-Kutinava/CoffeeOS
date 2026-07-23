# frozen_string_literal: true

require "test_helper"

class Shop::GuestCustomerResolverTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @email = "resolver-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    @session = {}
  end

  test "returns customer_id from session without email" do
    Shop::CustomerSession.set_customer_id!(@session, @tenant.id, @customer.id)
    assert_equal @customer.id.to_s,
      Shop::GuestCustomerResolver.call(session: @session, tenant_id: @tenant.id)
  end

  test "links from verified email when session empty" do
    Shop::EmailVerification.mark_verified!(
      session: @session,
      tenant_id: @tenant.id,
      email: @email
    )
    @session.delete(Shop::CustomerSession::BUCKET_KEY)
    @session.delete(Shop::CustomerSession::LEGACY_KEY)

    cid = Shop::GuestCustomerResolver.call(
      session: @session,
      tenant_id: @tenant.id,
      email: @email
    )
    assert_equal @customer.id.to_s, cid
    assert_equal @customer.id.to_s,
      Shop::CustomerSession.customer_id(@session, @tenant.id)
  end

  test "returns nil when email not verified" do
    assert_nil Shop::GuestCustomerResolver.call(
      session: @session,
      tenant_id: @tenant.id,
      email: @email
    )
  end
end
