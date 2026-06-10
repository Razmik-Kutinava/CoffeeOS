# frozen_string_literal: true

module Shop
  module Api
    class PushController < Shop::Api::BaseController
      def register
        unless Shop::FirebaseConfig.client_configured?
          return render json: { error: "Push не настроен на сервере", status: 503 }, status: :service_unavailable
        end

        customer = current_shop_customer
        return render json: { error: "Войдите по email перед подпиской на push", status: 401 }, status: :unauthorized unless customer

        customer = Shop::PushRegistrationService.call(
          customer: customer,
          push_token: params[:push_token],
          push_enabled: params.key?(:push_enabled) ? ActiveModel::Type::Boolean.new.cast(params[:push_enabled]) : true
        )

        render json: {
          push_enabled: customer.push_enabled,
          registered: customer.push_enabled && customer.push_token.present?
        }
      rescue Shop::PushRegistrationService::Error => e
        render json: { error: e.message, status: 422 }, status: :unprocessable_entity
      end

      private

      def current_shop_customer
        cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        return nil if cid.blank?

        MobileCustomer.find_by(id: cid)
      end
    end
  end
end
