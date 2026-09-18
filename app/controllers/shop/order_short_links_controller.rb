# frozen_string_literal: true

require "cgi"

module Shop
  # TASK_93-C / #82 — публичный entrypoint SMS short link `{host}/o/{order_hash}`.
  # Bind guest session + reconnect_token so cold-open from SMS can load order (bugbot).
  class OrderShortLinksController < ApplicationController
    skip_forgery_protection

    def show
      order = Shop::OrderReadySmsLink.find_order(params[:order_hash])
      return head :not_found unless order

      token = Shop::GuestOrderReconnect.token_for(order)
      Shop::GuestOrderReconnect.bind!(
        session,
        tenant_id: order.tenant_id,
        order_id: order.id,
        token: token
      )

      redirect_to(
        "/shop?tenant_id=#{order.tenant_id}&reconnect_token=#{CGI.escape(token)}#/order/#{order.id}",
        allow_other_host: false,
        status: :found
      )
    end
  end
end
