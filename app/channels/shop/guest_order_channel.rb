# frozen_string_literal: true

module Shop
  class GuestOrderChannel < ApplicationCable::Channel
    def subscribed
      order = Shop::GuestOrderReconnect.order_for_cable!(
        order_id: params[:order_id],
        tenant_id: params[:tenant_id],
        token: params[:reconnect_token]
      )
      return reject unless order

      stream_for order
    end

    def unsubscribed
      stop_all_streams
    end
  end
end
