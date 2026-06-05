# frozen_string_literal: true

module Shop
  module Api
    class SessionController < Shop::Api::BaseController
      def reconnect
        order = Shop::GuestOrderReconnect.bind!(
          session,
          tenant_id: @shop_tenant.id,
          order_id: params[:order_id],
          token: params[:reconnect_token]
        )

        if order
          render json: {
            ok: true,
            order_id: order.id,
            status: order.status,
            customer_id: order.customer_id
          }
        else
          render json: { error: "Не удалось восстановить сессию заказа" }, status: :unprocessable_entity
        end
      end
    end
  end
end
