# frozen_string_literal: true

require "test_helper"

class Barista::OrderBoardBroadcasterTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(name: "Broadcast", slug: "broadcast-tenant")
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista], email: "broadcast-barista@test.local")
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
    @order = Order.create!(
      tenant: @tenant, cash_shift: @shift, order_number: "BC-1",
      source: "manual", status: "accepted",
      total_amount: 100, discount_amount: 0, final_amount: 100
    )
  end

  test "call broadcasts replace on barista-board-slots and slot counts" do
    calls = []
    original = Turbo::StreamsChannel.method(:broadcast_replace_to)
    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) do |stream, **kwargs|
      calls << { stream: stream, **kwargs }
    end

    begin
      Barista::OrderBoardBroadcaster.call(order: @order, old_status: "pending_payment")
    ensure
      Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to, original)
    end

    slots = calls.find { |c| c[:target] == Barista::OrderBoardBroadcaster::BOARD_TARGET }
    assert slots, "expected broadcast_replace on #{Barista::OrderBoardBroadcaster::BOARD_TARGET}"
    assert_equal "orders_#{@tenant.id}", slots[:stream]
    assert_equal "barista/dashboard/board_slots", slots[:partial]
    assert_equal 1, slots[:locals][:orders].size

    %w[count-accepted count-preparing total-on-board].each do |target|
      assert calls.any? { |c| c[:target] == target }, "expected broadcast on #{target}"
    end
  end
end
