# frozen_string_literal: true

require "test_helper"

class Platform::TenantTransactionsOverviewTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @order = Order.create!(
      tenant: @tenant,
      order_number: "TX-1",
      source: "mobile",
      status: "accepted",
      total_amount: 250,
      discount_amount: 0,
      final_amount: 250
    )
    @payment = Payment.create!(
      tenant: @tenant,
      order: @order,
      amount: 250,
      method: "card",
      provider: "tbank",
      status: "succeeded",
      provider_payment_id: "tb-pay-123",
      paid_at: Time.current
    )
  end

  test "includes payment with provider id and summary" do
    data = Platform::TenantTransactionsOverview.new(@tenant).call

    assert_equal 1, data[:summary][:total_count]
    assert_equal 250.0, data[:summary][:succeeded_amount]
    row = data[:payments].first
    assert_equal @payment.id, row[:payment_id]
    assert_equal "tb-pay-123", row[:provider_payment_id]
    assert_equal "TX-1", row[:order_number]
    assert_includes row[:summary], "PaymentId tb-pay-123"
  end

  test "filters by status" do
    Payment.create!(
      tenant: @tenant,
      order: Order.create!(
        tenant: @tenant,
        order_number: "TX-2",
        source: "mobile",
        status: "cancelled",
        total_amount: 100,
        discount_amount: 0,
        final_amount: 100
      ),
      amount: 100,
      method: "card",
      provider: "tbank",
      status: "failed"
    )

    data = Platform::TenantTransactionsOverview.new(@tenant, status: "failed").call
    assert_equal 1, data[:payments].size
    assert_equal "failed", data[:payments].first[:status]
  end
end
