# frozen_string_literal: true

module Shop
  # #39 v2 — каскад «Заказ готов»: presence → SMS.ru (без Telegram).
  # Group 4: grace даёт время WS reconnect / push; SMS только если всё ещё offline.
  # #82 Патч_1: Presence fail → PresenceUnavailableError + retry_on (не silent swallow).
  class OrderReadyCascadeJob < ApplicationJob
    queue_as :default

    class PresenceUnavailableError < StandardError; end

    retry_on PresenceUnavailableError, wait: :polynomially_longer, attempts: 5

    # Пауза после ready: push/WS успевают, SMS — только если клиент не online.
    SMS_GRACE = 15.seconds
    # TASK_93-J: job starts after grace ends (+ skew) — avoid race with Presence grace expiry.
    SMS_GRACE_JOB_BUFFER = 5.seconds

    def perform(order_id)
      order = Order.find_by(id: order_id)
      return unless order&.ready? && order.source == "mobile"

      with_order_tenant!(order) do
        if presence_online?(order)
          Rails.logger.info(
            "[Cascade][Order ##{order.id}] User is online via WebSocket. SMS skipped."
          )
          return
        end

        Shop::OrderReadyPaidNotifier.call(order: order)
      end
    end

    private

    def presence_online?(order)
      Shop::OrderReadyPresence.online?(order.id)
    rescue StandardError => e
      Rails.logger.warn(
        "[Cascade][Order ##{order.id}] Presence unavailable: #{e.class} #{e.message}"
      )
      raise PresenceUnavailableError, e.message
    end
  end
end
