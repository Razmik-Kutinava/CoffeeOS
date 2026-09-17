# frozen_string_literal: true

module Shop
  # #82 Патч_1 — публичный entrypoint SMS short link codeblack.xyz/o/{order_hash}.
  class OrderShortLinksController < ApplicationController
    skip_forgery_protection

    def show
      order = Shop::OrderReadySmsLink.find_order(params[:order_hash])
      return head :not_found unless order

      redirect_to "/shop?tenant_id=#{order.tenant_id}#/order/#{order.id}",
                  allow_other_host: false,
                  status: :found
    end
  end
end
