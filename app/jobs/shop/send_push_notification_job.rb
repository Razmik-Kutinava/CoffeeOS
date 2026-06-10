# frozen_string_literal: true

module Shop
  class SendPushNotificationJob < ApplicationJob
    queue_as :default

    def perform(notification_id)
      notification = PushNotification.includes(:customer).find_by(id: notification_id)
      return unless notification&.pending?

      customer = notification.customer
      if customer.push_token.blank?
        notification.update!(status: :failed, error_message: "push_token missing")
        return
      end

      Shop::FcmClient.deliver!(
        token: customer.push_token,
        title: notification.title,
        body: notification.body,
        data: notification.payload
      )

      notification.update!(status: :sent, sent_at: Time.current, error_message: nil)
    rescue Shop::FcmClient::Error => e
      notification&.update!(status: :failed, error_message: e.message)
      Rails.logger.warn("[Shop::SendPushNotificationJob] #{e.message}")
    end
  end
end
