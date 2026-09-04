# frozen_string_literal: true

require "test_helper"

# #75 [TDD][RED] аудит попыток привязки card/sbp.
class CardBindingAttemptTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @customer = create_mobile_customer!(email: "attempt-#{SecureRandom.hex(3)}@example.com")
  end

  teardown do
    Current.reset
  end

  test "record! stores method_type method_hash phone_digest and growth flag" do
    row = CardBindingAttempt.record!(
      method_type: "card",
      method_hash: "abc123",
      phone: @customer.phone,
      account_id: @customer.id,
      device_fingerprint: "dev-1",
      ip: "127.0.0.1",
      bin: "220220",
      point_id: @tenant.id,
      result: "ok",
      reason: nil,
      verification_charge_required: false,
      is_growth_event: true
    )

    assert row.persisted?
    assert_equal "card", row.method_type
    assert_equal "abc123", row.method_hash
    assert_nil row.phone
    assert_equal CardBindingAttempt.phone_digest_for(@customer.phone), row.phone_digest
    assert_equal @customer.id, row.account_id
    assert row.is_growth_event
  end

  test "record! for sbp does not require bin" do
    row = CardBindingAttempt.record!(
      method_type: "sbp",
      method_hash: "sbp-hash-1",
      phone: @customer.phone,
      account_id: @customer.id,
      result: "ok",
      is_growth_event: false,
      point_id: @tenant.id
    )

    assert_equal "sbp", row.method_type
    assert_nil row.bin
  end
end
