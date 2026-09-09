# frozen_string_literal: true

require "test_helper"

class Barista::BroadcastOrderBoardJobTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    @tenant = create_tenant!(slug: "board-job-#{SecureRandom.hex(3)}")
    @order = Order.create!(
      tenant_id: @tenant.id,
      order_number: "BJ-#{SecureRandom.hex(2)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    Current.reset
  end

  teardown do
    Current.reset
  end

  test "perform no-ops when order missing" do
    assert_nothing_raised do
      Barista::BroadcastOrderBoardJob.perform_now(SecureRandom.uuid)
    end
  end

  test "perform sets Current.tenant_id from order while broadcasting" do
    captured = nil
    expected_order_id = @order.id
    original = Barista::OrderBoardBroadcaster.method(:call)
    Barista::OrderBoardBroadcaster.define_singleton_method(:call) do |order:, old_status: nil|
      captured = Current.tenant_id
      raise "unexpected order" unless order.id == expected_order_id
    end

    begin
      Barista::BroadcastOrderBoardJob.perform_now(@order.id, "pending_payment")
    ensure
      Barista::OrderBoardBroadcaster.define_singleton_method(:call, original)
    end

    assert_equal @tenant.id, captured, "job must set tenant GUC/Current from order before broadcast"
    assert_nil Current.tenant_id
  end
end
