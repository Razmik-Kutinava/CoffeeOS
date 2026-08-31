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

      def refresh
        result = Shop::SessionRefresh.call!(
          session: session,
          tenant_id: @shop_tenant.id,
          refresh_token: params[:refresh_token]
        )
        render json: result
      rescue Shop::SessionRefresh::Unauthorized
        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def destroy
        session_customer_id = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        Shop::CustomerSession.clear!(session, @shop_tenant.id)
        Shop::PendingOrderSession.clear!(session, @shop_tenant.id)
        token = params[:refresh_token].to_s.strip
        if token.present?
          ms = MobileSession.find_by(refresh_token: token)
          if ms && session_customer_id.present? &&
              ms.customer_id.to_s == session_customer_id.to_s
            ms.deactivate!
          end
        end
        render json: { ok: true, logged_out: true }
      end
    end
  end
end
