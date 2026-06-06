# frozen_string_literal: true

require "test_helper"

class Health::TenantEventFeedTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(name: "Feed Point", slug: "feed-#{SecureRandom.hex(3)}")
  end

  test "returns check_details for all monitoring keys" do
    result = Health::TenantEventFeed.new(@tenant).call

    %i[cash_register orders queue pending_payment kiosk shop_vitrina app payments inventory failed_payments].each do |key|
      assert result[:check_details].key?(key), "missing #{key}"
      assert result[:check_details][key].key?(:rows)
      assert result[:check_details][key].key?(:columns)
    end
  end

  test "pending_payment rows include stuck flag" do
    Order.create!(
      tenant: @tenant,
      order_number: "P-1",
      source: "mobile",
      status: "pending_payment",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100,
      created_at: 45.minutes.ago
    )

    rows = Health::TenantEventFeed.new(@tenant).call.dig(:check_details, :pending_payment, :rows)
    assert_equal 1, rows.size
    assert rows.first[:stuck]
  end

  test "unified_feed merges audit and status logs" do
    order = Order.create!(
      tenant: @tenant,
      order_number: "F-2",
      source: "mobile",
      status: "cancelled",
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )

    Shop::PaymentFailureJournal.record!(order: order, reason: :guest_abandon)
    OrderStatusLog.create!(
      order: order,
      status_from: "pending_payment",
      status_to: "cancelled",
      source: :customer,
      comment: "test"
    )

    feed = Health::TenantEventFeed.new(@tenant).call[:unified_feed]
    kinds = feed.map { |e| e[:kind] }.uniq
    assert_includes kinds, "audit"
    assert_includes kinds, "order_status"
  end
end
