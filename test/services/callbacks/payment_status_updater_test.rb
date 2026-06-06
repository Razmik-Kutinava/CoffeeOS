# frozen_string_literal: true

require "test_helper"

class Callbacks::PaymentStatusUpdaterTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @order = Order.create!(
      tenant: @tenant,
      order_number: "PAY-1",
      source: "mobile",
      status: "pending_payment",
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    @payment = Payment.create!(
      order: @order,
      tenant: @tenant,
      amount: 200,
      method: "card",
      provider: "shop",
      status: "pending"
    )
  end

  test "succeeded payment accepts order" do
    payment = Callbacks::PaymentStatusUpdater.new(
      payment: @payment,
      new_status: "succeeded",
      provider_data: { "ok" => true },
      provider_payment_id: "ext-1"
    ).call!

    assert_equal "succeeded", payment.status
    assert_equal "accepted", @order.reload.status
    assert PaymentStatusLog.exists?(payment: @payment, status_to: "succeeded")
    assert OrderStatusLog.exists?(order: @order, status_to: "accepted", source: "payment_callback")
  end

  test "rejects invalid status" do
    assert_raises(Callbacks::PaymentStatusUpdater::InvalidStatusError) do
      Callbacks::PaymentStatusUpdater.new(payment: @payment, new_status: "bogus").call!
    end
  end

  test "failed payment cancels pending order and journals" do
    assert_difference ["AdminAuditLog.count", "OrderStatusLog.count"], 1 do
      Callbacks::PaymentStatusUpdater.new(
        payment: @payment,
        new_status: "failed",
        provider_data: { "Status" => "REJECTED" },
        note: "Т-Банк: REJECTED"
      ).call!
    end

    assert_equal "failed", @payment.reload.status
    assert_equal "cancelled", @order.reload.status
    log = AdminAuditLog.order(created_at: :desc).first
    assert_equal Shop::PaymentFailureJournal::ACTION, log.action
    assert_equal "bank_rejected", log.details["reason"]
  end
end
