# frozen_string_literal: true

require "test_helper"

class Shop::GuestOrderReconnectTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(phone: "+79007776655")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
  end

  test "token_for and bind! restore customer in session" do
    session = {}
    token = Shop::GuestOrderReconnect.token_for(@order)

    bound = Shop::GuestOrderReconnect.bind!(
      session,
      tenant_id: @tenant.id,
      order_id: @order.id,
      token: token
    )

    assert_equal @order.id, bound.id
    assert_equal @customer.id.to_s, Shop::CustomerSession.customer_id(session, @tenant.id)
    assert_equal @order.id.to_s, Shop::PendingOrderSession.order_id(session, @tenant.id)
  end

  test "bind! rejects tampered token" do
    session = {}
    token = Shop::GuestOrderReconnect.token_for(@order)

    assert_nil Shop::GuestOrderReconnect.bind!(
      session,
      tenant_id: @tenant.id,
      order_id: @order.id,
      token: "#{token}x"
    )
  end
end
