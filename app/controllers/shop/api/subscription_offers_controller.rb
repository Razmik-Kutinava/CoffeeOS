# frozen_string_literal: true

module Shop
  module Api
    # TASK_95: фиксация показа / смахивания / просмотра оффера подписки гостем.
    class SubscriptionOffersController < Shop::Api::BaseController
      before_action :require_customer!

      def shown
        presentation_service.mark_shown
        render_state
      end

      def dismiss
        presentation_service.mark_dismissed
        render_state
      end

      def viewed
        presentation_service.mark_viewed_in_lk
        render_state
      end

      private

      def require_customer!
        cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        @customer = MobileCustomer.find_by(id: cid, is_active: true) if cid.present?
        return if @customer

        render json: { error: "Требуется авторизация" }, status: :unauthorized
      end

      def presentation_service
        @presentation_service ||= Subscriptions::OfferPresentationService.new(customer: @customer, point: @shop_tenant)
      end

      def render_state
        state = SubscriptionOfferState.find_by(customer_id: @customer.id)
        presentation = presentation_service.call
        render json: {
          status: state&.status || "not_shown",
          should_show_banner: presentation[:should_show_banner],
          has_unread_offer_in_lk: presentation[:has_unread_offer_in_lk]
        }
      end
    end
  end
end
