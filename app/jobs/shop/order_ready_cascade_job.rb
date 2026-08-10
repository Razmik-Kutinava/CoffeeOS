# frozen_string_literal: true

module Shop
  # #39 v2 — каскад «Заказ готов»: presence → SMS.ru (без Telegram).
  # Group 4: grace даёт время WS reconnect / push; SMS только если всё ещё offline.
  class OrderReadyCascadeJob < ApplicationJob
    queue_as :default

    # Пауза после ready: push/WS успевают, SMS — только если клиент не online.
    SMS_GRACE = 15.seconds

    def perform(order_id)
      order = Order.find_by(id: order_id)
      return unless order&.ready? && order.source == "mobile"

      if Shop::OrderReadyPresence.online?(order.id)
        Rails.logger.info(
          "[Cascade][Order ##{order.id}] User is online via WebSocket. SMS skipped."
        )
        return
      end

      Shop::OrderReadyPaidNotifier.call(order: order)
    end
  end
end
