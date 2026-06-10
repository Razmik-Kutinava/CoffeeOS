# frozen_string_literal: true

require "test_helper"

class Shop::GuestOrderChannelTest < ActionCable::Channel::TestCase
  include TestFactories

  tests Shop::GuestOrderChannel

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(phone: "+79001112299")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "202606-0001",
      source: :mobile,
      status: :accepted,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    @token = Shop::GuestOrderReconnect.token_for(@order)
  end

  test "rejects subscription without reconnect token" do
    subscribe order_id: @order.id, tenant_id: @tenant.id

    assert subscription.rejected?
  end

  test "subscribes with valid reconnect token" do
    subscribe order_id: @order.id, tenant_id: @tenant.id, reconnect_token: @token

    assert subscription.confirmed?
    assert_has_stream_for @order
  end

  test "receives status broadcast" do
    subscribe order_id: @order.id, tenant_id: @tenant.id, reconnect_token: @token

    assert_broadcasts(Shop::GuestOrderChannel.broadcasting_for(@order), 1) do
      @order.update!(status: :preparing)
      Shop::GuestOrderBroadcaster.call(order: @order.reload, old_status: "accepted")
    end
  end
end
