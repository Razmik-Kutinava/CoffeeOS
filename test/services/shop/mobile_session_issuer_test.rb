# frozen_string_literal: true

require "test_helper"

class Shop::MobileSessionIssuerTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @customer = create_mobile_customer!(email: "issuer-#{SecureRandom.hex(3)}@example.com")
  end

  test "issues active mobile session with 90 day expiry and hex refresh token" do
    token = Shop::MobileSessionIssuer.call!(customer_id: @customer.id)

    assert_match(/\A[0-9a-f]{64}\z/, token)
    session = MobileSession.find_by!(refresh_token: token)
    assert_equal @customer.id, session.customer_id
    assert session.is_active
    assert_in_delta 90.days.from_now.to_i, session.expires_at.to_i, 5
  end

  test "deactivates previous active sessions for same customer" do
    old = Shop::MobileSessionIssuer.call!(customer_id: @customer.id)
    new_token = Shop::MobileSessionIssuer.call!(customer_id: @customer.id)

    refute_equal old, new_token
    assert_equal false, MobileSession.find_by!(refresh_token: old).is_active
    assert MobileSession.find_by!(refresh_token: new_token).is_active
  end
end
