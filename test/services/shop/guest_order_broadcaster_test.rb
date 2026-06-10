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

  test "broadcasts mobile order without error" do
    assert_nothing_raised do
      Shop::GuestOrderBroadcaster.call(order: @order, old_status: "accepted")
    end
  end

  test "skips non-mobile orders without error" do
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

    assert_nothing_raised do
      Shop::GuestOrderBroadcaster.call(order: kiosk)
    end
  end
end
