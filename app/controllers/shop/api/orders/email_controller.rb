module Shop
  module Api
    module Orders
      class EmailController < Shop::Api::BaseController
        def create
          order = Order.where(tenant_id: @shop_tenant.id, source: :mobile).find(params[:order_id])
          unless order_visible_to_session_customer?(order)
            return render json: { error: "Order not found" }, status: :not_found
          end

          email_service = ::Orders::EmailService.new(order)
          result = email_service.save_email(
            email: params[:email],
            marketing_consent: ActiveModel::Type::Boolean.new.cast(params[:marketing_consent])
          )

          render json: result
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Order not found" }, status: :not_found
        rescue ::Orders::EmailService::ValidationError => e
          render json: { error: e.message }, status: :bad_request
        rescue => e
          Rails.logger.error("[OrderEmail] Error: #{e.message}")
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        private

        # Канон как OrdersController: session customer / pending order / reconnect_token
        def order_visible_to_session_customer?(order)
          cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
          if cid.present? && order.customer_id.present? && order.customer_id.to_s == cid.to_s
            return true
          end

          pending_id = Shop::PendingOrderSession.order_id(session, @shop_tenant.id)
          if pending_id.present? && pending_id.to_s == order.id.to_s
            Shop::CustomerSession.set_customer_id!(session, @shop_tenant.id, order.customer_id) if order.customer_id.present?
            return true
          end

          token = params[:reconnect_token].presence
          if token.present?
            rebound = Shop::GuestOrderReconnect.bind!(
              session,
              tenant_id: @shop_tenant.id,
              order_id: order.id,
              token: token
            )
            return rebound.present?
          end

          false
        end
      end
    end
  end
end
