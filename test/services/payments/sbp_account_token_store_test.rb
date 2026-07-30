# frozen_string_literal: true

require "test_helper"

# RED [TDD] #34 Шаг 2: сохранение AccountToken + идемпотентность RequestKey.
class Payments::SbpAccountTokenStoreTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @customer = create_mobile_customer!(email: "sbp-autopay-#{SecureRandom.hex(3)}@example.com")
  end

  test "SbpAccountTokenStore class is defined" do
    assert defined?(Payments::SbpAccountTokenStore),
      "[TDD] ожидается Payments::SbpAccountTokenStore"
  end

  test "persist! saves AccountToken as mobile_payment_methods payment_type=sbp" do
    row = Payments::SbpAccountTokenStore.persist!(
      customer_id: @customer.id,
      account_token: "acct-token-A",
      request_key: "rk-1"
    )

    assert_equal "sbp", row.payment_type
    assert_equal "acct-token-A", row.card_token
    assert row.is_active
  end

  test "persist! appends second AccountToken without overwriting first" do
    Payments::SbpAccountTokenStore.persist!(
      customer_id: @customer.id,
      account_token: "acct-token-A",
      request_key: "rk-1"
    )
    Payments::SbpAccountTokenStore.persist!(
      customer_id: @customer.id,
      account_token: "acct-token-B",
      request_key: "rk-2"
    )

    tokens = MobilePaymentMethod.where(customer_id: @customer.id, payment_type: "sbp", is_active: true)
      .pluck(:card_token).sort
    assert_equal %w[acct-token-A acct-token-B], tokens
  end

  test "persist! is idempotent for the same RequestKey" do
    a = Payments::SbpAccountTokenStore.persist!(
      customer_id: @customer.id,
      account_token: "acct-token-A",
      request_key: "rk-dup"
    )
    b = Payments::SbpAccountTokenStore.persist!(
      customer_id: @customer.id,
      account_token: "acct-token-A",
      request_key: "rk-dup"
    )

    assert_equal a.id, b.id
    assert_equal 1, MobilePaymentMethod.where(customer_id: @customer.id, payment_type: "sbp").count
  end

  test "soft decline must not deactivate AccountToken" do
    row = Payments::SbpAccountTokenStore.persist!(
      customer_id: @customer.id,
      account_token: "acct-keep",
      request_key: "rk-keep"
    )

    Payments::SbpAccountTokenStore.handle_charge_outcome!(
      customer_id: @customer.id,
      account_token: "acct-keep",
      fatal: false
    )

    assert row.reload.is_active, "soft decline — AccountToken остаётся активным"
  end

  test "fatal decline deactivates AccountToken without hard delete" do
    row = Payments::SbpAccountTokenStore.persist!(
      customer_id: @customer.id,
      account_token: "acct-fatal",
      request_key: "rk-fatal"
    )

    Payments::SbpAccountTokenStore.handle_charge_outcome!(
      customer_id: @customer.id,
      account_token: "acct-fatal",
      fatal: true
    )

    assert_not row.reload.is_active
    assert MobilePaymentMethod.exists?(id: row.id), "hard delete запрещён"
  end
end
