# frozen_string_literal: true

require "cgi"

module Shop
  # TASK_93-C / #82 — публичный entrypoint SMS short link `{host}/o/{order_hash}`.
  # TASK_117 — не перезаписывать чужого клиента без confirm; reconnect_token не в Location.
  class OrderShortLinksController < ApplicationController
    skip_forgery_protection

    def show
      order = Shop::OrderReadySmsLink.find_order(params[:order_hash])
      return head :not_found unless order

      if Shop::SmsSessionTransition.conflict?(session, order)
        pending = Shop::SmsSessionTransition.pending_token_for(order)
        redirect_to(
          "/shop?tenant_id=#{order.tenant_id}&sms_transition=#{CGI.escape(pending)}",
          allow_other_host: false,
          status: :found
        )
        return
      end

      token = Shop::GuestOrderReconnect.token_for(order)
      Shop::GuestOrderReconnect.bind!(
        session,
        tenant_id: order.tenant_id,
        order_id: order.id,
        token: token
      )

      redirect_to(
        "/shop?tenant_id=#{order.tenant_id}#/order/#{order.id}",
        allow_other_host: false,
        status: :found
      )
    end
  end
end
