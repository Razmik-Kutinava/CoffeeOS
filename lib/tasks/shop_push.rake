# frozen_string_literal: true

namespace :shop do
  namespace :push do
    desc "Симуляция push pipeline для заказа (FCM_SIMULATE=1, без Google). ORDER_ID=uuid"
    task smoke: :environment do
      order_id = ENV.fetch("ORDER_ID") do
        abort "Укажите ORDER_ID=uuid mobile-заказа"
      end

      ENV["FCM_SIMULATE"] = "1"
      order = Order.find(order_id)
      old_status = order.status
      target = ENV.fetch("STATUS", "preparing")

      unless order.source == "mobile"
        abort "Заказ #{order_id} не mobile (source=#{order.source})"
      end

      customer = order.customer
      if customer.blank? || customer.push_token.blank?
        token = ENV.fetch("PUSH_TOKEN", "shop-push-smoke-#{SecureRandom.hex(4)}")
        customer ||= MobileCustomer.find_or_initialize_by(email: ENV.fetch("EMAIL", "push-smoke@coffeeos.dev"))
        customer.update!(push_enabled: true, push_token: token, is_active: true, first_name: "Push", last_name: "Smoke")
        order.update!(customer_id: customer.id) if order.customer_id.blank?
      end

      order.update!(status: target) unless order.status == target
      Shop::OrderStatusPushNotifier.call(order: order.reload, old_status: old_status)

      notification = PushNotification.order(created_at: :desc).first
      abort "PushNotification не создан" unless notification

      Shop::SendPushNotificationJob.perform_now(notification.id)
      notification.reload

      puts JSON.pretty_generate(
        order_id: order.id,
        old_status: old_status,
        new_status: order.status,
        notification_id: notification.id,
        body: notification.body,
        status: notification.status,
        sent_at: notification.sent_at&.iso8601,
        fcm_simulate: true
      )
    end
  end
end
