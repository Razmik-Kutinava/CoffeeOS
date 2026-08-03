# frozen_string_literal: true

module Shop
  # #39 — каскад «Заказ готов»: presence → Telegram → SMS.ru.
  # Шаг 1: skeleton + enqueue из GuestOrderBroadcaster при ready.
  class OrderReadyCascadeJob < ApplicationJob
    queue_as :default

    def perform(order_id)
      order = Order.find_by(id: order_id)
      return unless order&.ready? && order.source == "mobile"

      # Шаги 2–5: presence / Telegram / SMS
      Rails.logger.info("[Cascade][Order ##{order.id}] cascade job started (skeleton)")
    end
  end
end
