# frozen_string_literal: true

require "test_helper"

class Shop::GuestOrderBroadcasterTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(phone: "+79003334455")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "202606-0002",
      source: :mobile,
      status: :preparing,
      total_amount: 150,
      discount_amount: 0,
      final_amount: 150
    )
  end

  test "broadcasts mobile order status payload" do
    assert_broadcasts(Shop::GuestOrderChannel.broadcasting_for(@order), 1) do
      Shop::GuestOrderBroadcaster.call(order: @order, old_status: "accepted")
    end
  end

  test "skips non-mobile orders" do
    kiosk = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Kiosk",
      order_number: "202606-0003",
      source: :kiosk,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )

    assert_no_broadcasts do
      Shop::GuestOrderBroadcaster.call(order: kiosk)
    end
  end
end
