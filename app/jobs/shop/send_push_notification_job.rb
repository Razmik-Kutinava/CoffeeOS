# frozen_string_literal: true

module Shop
  class SendPushNotificationJob < ApplicationJob
    queue_as :default

    def perform(notification_id)
      notification = PushNotification.includes(:customer).find_by(id: notification_id)
      return unless notification&.pending?

      with_job_tenant_id!(notification.tenant_id) do
        customer = notification.customer
        if customer.push_token.blank?
          notification.update!(status: :failed, error_message: "push_token missing")
          return
        end

        Shop::FcmClient.deliver!(
          token: customer.push_token,
          title: notification.title,
          body: notification.body,
          data: notification.payload,
          customer: customer
        )

        notification.update!(status: :sent, sent_at: Time.current, error_message: nil)
        log_offer_push_sent(notification)
      end
    rescue Shop::FcmClient::Error => e
      notification&.update!(status: :failed, error_message: e.message)
      Rails.logger.warn("[Shop::SendPushNotificationJob] #{e.message}")
    end

    private

    def log_offer_push_sent(notification)
      return unless notification.notification_type == Subscriptions::OfferPushNotifier::NOTIFICATION_TYPE

      Subscriptions::MarketingEventLogger.log(
        event_type: :push_sent,
        customer_id: notification.customer_id,
        point_id: notification.tenant_id,
        channel: Subscriptions::OfferPushNotifier::CHANNEL,
        utm_campaign: Subscriptions::OfferPushNotifier::UTM_CAMPAIGN,
        utm_content: Subscriptions::OfferPushNotifier::UTM_CONTENT,
        metadata: { "push_notification_id" => notification.id }
      )
    end
  end
end
