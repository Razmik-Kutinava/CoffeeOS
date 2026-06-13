# frozen_string_literal: true

module Barista
  # Live-обновление табло бариста через Turbo Streams / Solid Cable.
  class OrderBoardBroadcaster
    BOARD_TARGET = "barista-board-slots"

    def self.call(order:, old_status: nil)
      new(order: order, old_status: old_status).call
    end

    def initialize(order:, old_status: nil)
      @order = order
      @old_status = old_status
    end

    def call
      tenant_id = @order.tenant_id
      resync_board_slots(tenant_id)
      broadcast_slot_counts(tenant_id)
      BroadcastTvColumnsJob.perform_later(tenant_id)
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.warn("[Barista::OrderBoardBroadcaster] cable unavailable: #{e.class} #{e.message}")
    end

    private

    def resync_board_slots(tenant_id)
      Turbo::StreamsChannel.broadcast_replace_to(
        stream_for(tenant_id),
        target: BOARD_TARGET,
        partial: "barista/dashboard/board_slots",
        locals: {
          orders: BoardOrdersQuery.for_slots(tenant_id: tenant_id)
        }
      )
    end

    def stream_for(tenant_id)
      "orders_#{tenant_id}"
    end

    def broadcast_slot_counts(tenant_id)
      counts = BoardOrdersQuery.slot_counts(tenant_id: tenant_id)

      {
        "count-accepted" => counts[:accepted],
        "count-preparing" => counts[:preparing],
        "total-on-board" => counts[:total]
      }.each do |target, count|
        Turbo::StreamsChannel.broadcast_replace_to(
          stream_for(tenant_id),
          target: target,
          html: count.to_s
        )
      end
    end
  end
end
