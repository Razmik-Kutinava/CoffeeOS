# frozen_string_literal: true

require "test_helper"

# #35 C1/C2 — атомарный claim ready_notified_at перед ready-push [TDD RED]
class Shop::ReadyPushClaimTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(
      phone: "+79001113502",
      email: "ready-claim-#{SecureRandom.hex(3)}@example.com"
    )
    @customer.update!(push_enabled: true, push_token: "fcm-ready-claim")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Ready Claim",
      order_number: "202607-3502",
      source: :mobile,
      status: :ready,
      total_amount: 180,
      discount_amount: 0,
      final_amount: 180
    )
  end

  test "#35 orders table has ready_notified_at column" do
    assert_includes Order.column_names, "ready_notified_at",
      "#35 C1: нужна колонка orders.ready_notified_at (Migration Gate + go)"
  end

  test "#35 claim! returns true once then false" do
    assert Shop::ReadyPushClaim.claim!(@order), "first claim must win"
    assert @order.reload.ready_notified_at.present?
    assert_not Shop::ReadyPushClaim.claim!(@order.reload), "second claim must skip"
  end

  test "#35 notifier skips ready push when already claimed" do
    assert Shop::ReadyPushClaim.claim!(@order)

    assert_no_enqueued_jobs(only: Shop::SendPushNotificationJob) do
      Shop::OrderStatusPushNotifier.call(order: @order.reload, old_status: "preparing")
    end
  end

  test "#35 notifier claims and enqueues on first ready" do
    assert_nil @order.ready_notified_at

    assert_enqueued_with(job: Shop::SendPushNotificationJob) do
      Shop::OrderStatusPushNotifier.call(order: @order, old_status: "preparing")
    end

    assert @order.reload.ready_notified_at.present?
  end
end
