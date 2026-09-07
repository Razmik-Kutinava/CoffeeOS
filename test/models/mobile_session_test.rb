# frozen_string_literal: true

require "test_helper"

class MobileSessionTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @customer = create_mobile_customer!(email: "ms-#{SecureRandom.hex(3)}@example.com")
  end

  def build_session!(suffix:)
    MobileSession.create!(
      customer_id: @customer.id,
      refresh_token: "tok-#{suffix}-#{SecureRandom.hex(8)}",
      is_active: true,
      expires_at: 90.days.from_now,
      last_used_at: Time.current
    )
  end

  test "deactivate! clears active and rewrites refresh_token uniquely" do
    a = build_session!(suffix: "a")
    b = build_session!(suffix: "b")
    old_a = a.refresh_token
    old_b = b.refresh_token

    a.deactivate!
    b.deactivate!

    a.reload
    b.reload
    refute a.is_active
    refute b.is_active
    refute_equal old_a, a.refresh_token
    refute_equal old_b, b.refresh_token
    refute_equal a.refresh_token, b.refresh_token
    assert_match(/\Arevoked-#{a.id}-[0-9a-f]{32}\z/, a.refresh_token)
    assert_match(/\Arevoked-#{b.id}-[0-9a-f]{32}\z/, b.refresh_token)
  end
end
