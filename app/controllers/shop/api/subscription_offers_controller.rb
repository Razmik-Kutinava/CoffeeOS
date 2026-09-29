# frozen_string_literal: true

module Shop
  module Api
    # TASK_95: фиксация показа / смахивания / просмотра оффера подписки гостем.
    # TASK_96: события воронки (banner_dismissed / lk_viewed / offer_opened / push_opened).
    class SubscriptionOffersController < Shop::Api::BaseController
      before_action :require_customer!

      def shown
        presentation_service.mark_shown
        render_state
      end

      def dismiss
        presentation_service.mark_dismissed
        log_event(:banner_dismissed, channel: "banner")
        render_state
      end

      def viewed
        presentation_service.mark_viewed_in_lk
        log_event(:lk_viewed, channel: "lk")
        render_state
      end

      # sendBeacon не ставит Content-Type: application/json — тело разбираем сами.
      def opened
        data = opened_payload
        channel = data["channel"].to_s
        unless MarketingEvent::CHANNELS.include?(channel)
          return render json: { error: "invalid channel" }, status: :unprocessable_entity
        end

        metadata = {}
        metadata["push_notification_id"] = data["push_notification_id"].to_s if data["push_notification_id"].present?
        log_event(
          channel == "push" ? :push_opened : :offer_opened,
          channel: channel,
          utm_campaign: data["utm_campaign"].to_s.first(100),
          utm_content: data["utm_content"].to_s.first(100),
          metadata: metadata
        )
        head :no_content
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

      def log_event(event_type, **attrs)
        Subscriptions::MarketingEventLogger.log(
          event_type: event_type, customer_id: @customer.id, point_id: @shop_tenant.id, **attrs
        )
      end

      def opened_payload
        keys = %w[channel utm_campaign utm_content push_notification_id]
        from_params = params.permit(*keys).to_h
        return from_params if from_params["channel"].present?

        raw = JSON.parse(request.raw_post.presence || "{}")
        raw.is_a?(Hash) ? raw.slice(*keys) : {}
      rescue JSON::ParserError
        {}
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
