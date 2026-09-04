# frozen_string_literal: true

require "test_helper"

# #75 [TDD][RED] SBP method_hash uniqueness + controlled refusal without owner leak.
class Payments::SbpMethodHashBindingTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @customer_a = create_mobile_customer!(email: "sbp-hash-a-#{SecureRandom.hex(3)}@example.com")
    @customer_b = create_mobile_customer!(email: "sbp-hash-b-#{SecureRandom.hex(3)}@example.com")
  end

  teardown do
    Current.reset
  end

  test "persist sets stable method_hash from AccountToken" do
    row = Payments::SbpAccountTokenStore.persist!(
      customer_id: @customer_a.id,
      account_token: "acct-shared-token-1",
      request_key: "rk-hash-1"
    )

    expected = Payments::SbpAccountTokenStore.method_hash_for("acct-shared-token-1")
    assert expected.present?
    assert_equal expected, row.card_hash
    assert_equal expected, row.method_hash
  end

  test "second account cannot bind same AccountToken — blocked_method_taken without leak" do
    first = Payments::SbpAccountTokenStore.persist!(
      customer_id: @customer_a.id,
      account_token: "acct-shared-token-2",
      request_key: "rk-hash-2"
    )
    assert first.persisted?

    result = nil
    error = nil
    begin
      result = Payments::SbpAccountTokenStore.persist!(
        customer_id: @customer_b.id,
        account_token: "acct-shared-token-2",
        request_key: "rk-hash-2b"
      )
    rescue StandardError => e
      error = e
    end

    assert_nil error, "unique conflict must not raise: #{error&.class}: #{error&.message}"
    assert_equal :blocked_method_taken, result

    hash = Payments::SbpAccountTokenStore.method_hash_for("acct-shared-token-2")
    assert_equal 1, MobilePaymentMethod.where(card_hash: hash, payment_type: "sbp", is_active: true).count
    assert_equal 0, MobilePaymentMethod.where(customer_id: @customer_b.id, payment_type: "sbp", is_active: true).count
  end
end
