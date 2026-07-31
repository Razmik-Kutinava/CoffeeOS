# frozen_string_literal: true

module Shop
  # #35 B3 — ready: Apple Wallet update + FCM. Wallet unavailable → FCM only.
  # GenerationError → raise (ActiveJob retry). Не блокирует POS (async).
  class ReadyPushJob < ApplicationJob
    queue_as :default

    READY_BODY = "Ваш кофе готов! Заберите на кассе"
    # B2.1 совместимый текст тоже принимаем в тестах notifier path; job шлёт ТЗ-копию.
    TITLE = "Заказ готов"

    def perform(order_id, old_status = "preparing")
      order = Order.find_by(id: order_id)
      return unless order&.ready? && order.source == "mobile"
      return if order.customer_id.blank?

      customer = MobileCustomer.find_by(id: order.customer_id)
      return unless customer&.push_enabled? && customer.push_token.present?

      update_wallet!(order)
      deliver_fcm!(order, customer, old_status)
    end

    private

    def update_wallet!(order)
      Shop::AppleWallet::PassUpdater.call!(order: order)
    rescue Shop::AppleWallet::UnavailableError => e
      Rails.logger.info("[Shop::ReadyPushJob] wallet fallback FCM-only: #{e.message}")
    end

    def deliver_fcm!(order, customer, old_status)
      body = if old_status.to_s == "preparing"
        READY_BODY
      else
        Shop::OrderStatusPushNotifier::BARISTA_TRANSITION_BODIES[[old_status.to_s, "ready"]] || READY_BODY
      end

      notification = PushNotification.create!(
        customer_id: customer.id,
        tenant_id: order.tenant_id,
        notification_type: "order_status",
        title: TITLE,
        body: body,
        payload: {
          order_id: order.id,
          status: order.status,
          order_number: order.order_number,
          channel: "ready_push"
        },
        status: :pending
      )

      Shop::SendPushNotificationJob.perform_now(notification.id)
    end
  end
end
