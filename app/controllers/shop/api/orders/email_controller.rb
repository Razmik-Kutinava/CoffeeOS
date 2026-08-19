module Shop
  module Api
    module Orders
      class EmailController < Shop::Api::BaseController
        def create
          order = Order.where(tenant_id: @shop_tenant.id, source: :mobile).find(params[:order_id])
          unless order_visible_to_session_customer?(order)
            return render json: { error: "Order not found" }, status: :not_found
          end

          email_service = Orders::EmailService.new(order)
          result = email_service.save_email(
            email: params[:email],
            marketing_consent: params[:marketing_consent]
          )

          render json: result
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Order not found" }, status: :not_found
        rescue Orders::EmailService::ValidationError => e
          render json: { error: e.message }, status: :bad_request
        rescue => e
          Rails.logger.error("[OrderEmail] Error: #{e.message}")
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        private

        def order_visible_to_session_customer?(order)
          customer_id = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
          order.customer_id.nil? || order.customer_id == customer_id
        end
      end
    end
  end
end
