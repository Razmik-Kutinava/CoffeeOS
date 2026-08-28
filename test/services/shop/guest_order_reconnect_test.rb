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

  test "order_for_cable! accepts customer session when reconnect token is for another order" do
    other = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Other",
      order_number: "X-2",
      source: :mobile,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    stale = Shop::GuestOrderReconnect.token_for(other)

    found = Shop::GuestOrderReconnect.order_for_cable!(
      order_id: @order.id,
      tenant_id: @tenant.id,
      token: stale,
      customer_id: @customer.id
    )

    assert_equal @order.id, found.id
  end

  test "owned_by_session? accepts reconnect token" do
    session = {}
    token = Shop::GuestOrderReconnect.token_for(@order)

    assert Shop::GuestOrderReconnect.owned_by_session?(session, order: @order, reconnect_token: token)
    assert_equal @customer.id.to_s, Shop::CustomerSession.customer_id(session, @tenant.id)
  end

  test "owned_by_session? accepts pending order session" do
    session = {}
    Shop::PendingOrderSession.set!(session, @tenant.id, @order.id)

    assert Shop::GuestOrderReconnect.owned_by_session?(session, order: @order)
  end

  test "owned_by_session? rejects foreign order" do
    session = {}
    other = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Other",
      order_number: "X-9",
      source: :mobile,
      status: :pending_payment,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    Shop::PendingOrderSession.set!(session, @tenant.id, other.id)

    assert_not Shop::GuestOrderReconnect.owned_by_session?(session, order: @order)
  end
end
