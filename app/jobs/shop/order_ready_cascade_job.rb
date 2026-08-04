# frozen_string_literal: true

module Shop
  # #39 — каскад «Заказ готов»: presence → Telegram → SMS.ru.
  class OrderReadyCascadeJob < ApplicationJob
    queue_as :default

    def perform(order_id)
      order = Order.find_by(id: order_id)
      return unless order&.ready? && order.source == "mobile"

      if Shop::OrderReadyPresence.online?(order.id)
        Rails.logger.info(
          "[Cascade][Order ##{order.id}] User is online via WebSocket. Paid channels skipped."
        )
        return
      end

      Shop::OrderReadyPaidNotifier.call(order: order)
    end
  end
end
