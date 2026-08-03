# frozen_string_literal: true

module Shop
  class GuestOrderChannel < ApplicationCable::Channel
    def subscribed
      order = authorized_order
      return reject unless order

      @presence_order_id = order.id
      Shop::OrderReadyPresence.mark_online!(@presence_order_id)
      stream_for order
    end

    def unsubscribed
      Shop::OrderReadyPresence.mark_offline!(@presence_order_id) if @presence_order_id
      stop_all_streams
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
  end
end
