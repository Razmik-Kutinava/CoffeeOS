# frozen_string_literal: true

module Shop
  module Api
    module Orders
      class EmailController < Shop::Api::BaseController
        include Shop::Api::OrderOwnership

        def create
          order = Order.where(tenant_id: @shop_tenant.id, source: :mobile).find(params[:order_id])
          unless order_visible_to_session?(order)
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
      end
    end
  end
end
