# frozen_string_literal: true

module Shop
  class GuestOrderChannel < ApplicationCable::Channel
    def subscribed
      order = authorized_order
      return reject unless order

      stream_for order
    end

    private

    def authorized_order
      tenant_id = params[:tenant_id]
      order_id = params[:order_id]
      token = params[:reconnect_token].presence
      shop_session = connection.respond_to?(:session) ? connection.session : {}
      customer_id = Shop::CustomerSession.customer_id(shop_session, tenant_id)

      Shop::GuestOrderReconnect.order_for_cable!(
        order_id: order_id,
        tenant_id: tenant_id,
        token: token,
        customer_id: customer_id
      )
    end

    def unsubscribed
      stop_all_streams
    end
  end
end
