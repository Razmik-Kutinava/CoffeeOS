# frozen_string_literal: true

module Shop
  # WebSocket-уведомление гостя на экране /order/:id (B1.1).
  class GuestOrderBroadcaster
    def self.call(order:, old_status: nil)
      return unless order.source == "mobile"

      Shop::GuestOrderChannel.broadcast_to(
        order,
        {
          type: "status_changed",
          order_id: order.id,
          status: order.status,
          payment_settled: !order.pending_payment?,
          old_status: old_status
        }
      )
    rescue StandardError => e
      Rails.logger.warn("[Shop::GuestOrderBroadcaster] cable unavailable: #{e.class} #{e.message}")
    end
  end
end
