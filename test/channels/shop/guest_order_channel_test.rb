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

  test "rejects subscription without reconnect token or customer session" do
    stub_connection(session: {})
    subscribe order_id: @order.id, tenant_id: @tenant.id

    assert subscription.rejected?
  end

  test "subscribes with customer session without reconnect token" do
    shop_session = {}
    Shop::CustomerSession.set_customer_id!(shop_session, @tenant.id, @customer.id)
    stub_connection(session: shop_session)

    subscribe order_id: @order.id, tenant_id: @tenant.id

    assert subscription.confirmed?
    assert_has_stream_for @order
  end

  test "subscribes with valid reconnect token" do
    subscribe order_id: @order.id, tenant_id: @tenant.id, reconnect_token: @token

    assert subscription.confirmed?
    assert_has_stream_for @order
  end

  test "subscribes with stale reconnect token when customer session matches" do
    other = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Other",
      order_number: "202606-0002",
      source: :mobile,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    stale_token = Shop::GuestOrderReconnect.token_for(other)

    shop_session = {}
    Shop::CustomerSession.set_customer_id!(shop_session, @tenant.id, @customer.id)
    stub_connection(session: shop_session)

    subscribe order_id: @order.id, tenant_id: @tenant.id, reconnect_token: stale_token

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

  # B2.1 этап 3 — бариста меняет статус → WS гостю
  test "b21 barista status update broadcasts to guest" do
    subscribe order_id: @order.id, tenant_id: @tenant.id, reconnect_token: @token

    barista = create_user!(tenant: @tenant, role_codes: %w[barista])
    shift = open_cash_shift!(tenant: @tenant, opened_by: barista)
    @order.update!(cash_shift: shift)

    assert_broadcasts(Shop::GuestOrderChannel.broadcasting_for(@order), 1) do
      Barista::OrderStatusUpdateService.new(
        order: @order,
        new_status: "preparing",
        user_id: barista.id
      ).call!
    end
  end
end
