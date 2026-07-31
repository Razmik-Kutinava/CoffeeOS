# frozen_string_literal: true

require "test_helper"

# #35 A1 — контракт payload GuestOrderChannel для sticky-шторки [TDD RED]
class Shop::GuestOrderBroadcasterSheetContractTest < ActionCable::Channel::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(name: "Point A Sticky")
    @customer = create_mobile_customer!(phone: "+79001113501")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Sheet Guest",
      order_number: "202607-3501",
      source: :mobile,
      status: :preparing,
      total_amount: 220,
      discount_amount: 0,
      final_amount: 220
    )
  end

  test "#35 broadcast payload has order_id status and order_number for sticky sheet" do
    expected = {
      "type" => "status_changed",
      "order_id" => @order.id,
      "status" => "preparing",
      "payment_settled" => true,
      "old_status" => "accepted",
      "order_number" => "202607-3501"
    }

    assert_broadcast_on(Shop::GuestOrderChannel.broadcasting_for(@order), expected) do
      Shop::GuestOrderBroadcaster.call(order: @order, old_status: "accepted")
    end
  end
end
