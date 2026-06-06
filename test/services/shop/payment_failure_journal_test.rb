# frozen_string_literal: true

require "test_helper"

class Shop::PaymentFailureJournalTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @order = Order.create!(
      tenant: @tenant,
      order_number: "J-1",
      source: :mobile,
      status: :pending_payment,
      total_amount: 300,
      discount_amount: 0,
      final_amount: 300
    )
    @payment = Payment.create!(
      order: @order,
      tenant: @tenant,
      amount: 300,
      method: :card,
      provider: "tbank",
      status: :pending
    )
  end

  test "guest_abandon cancels order and writes audit log" do
    assert_difference ["OrderStatusLog.count", "AdminAuditLog.count"], 1 do
      Shop::PaymentFailureJournal.record!(
        order: @order,
        payment: @payment,
        reason: :guest_abandon,
        source: :customer
      )
    end

    assert_equal "cancelled", @order.reload.status
    assert_equal "failed", @payment.reload.status
    log = AdminAuditLog.order(created_at: :desc).first
    assert_equal Shop::PaymentFailureJournal::ACTION, log.action
    assert_equal "guest_abandon", log.details["reason"]
  end

  test "bank_rejected from callback" do
    Shop::PaymentFailureJournal.record!(
      order: @order,
      payment: @payment,
      reason: :bank_rejected,
      source: :payment_callback,
      details: { provider_status: "REJECTED" }
    )

    olog = OrderStatusLog.find_by!(order_id: @order.id, status_to: "cancelled")
    assert_equal "payment_callback", olog.source
  end

  test "recent_for_tenant returns journal events" do
    Shop::PaymentFailureJournal.record!(order: @order, payment: @payment, reason: :guest_abandon)

    events = Shop::PaymentFailureJournal.recent_for_tenant(@tenant.id)
    assert_equal 1, events.size
    assert_equal "guest_abandon", events.first[:reason]
  end
end
