# frozen_string_literal: true

module Barista
  # Live-обновление канбан-табло барista через Turbo Streams / Solid Cable.
  class OrderBoardBroadcaster
    def self.call(order:, old_status: nil)
      new(order: order, old_status: old_status).call
    end

    CARD_INCLUDES = [:order_items, :order_status_logs, :customer].freeze

    def initialize(order:, old_status: nil)
      @order = order
      @old_status = old_status
    end

    def call
      @order = Order.includes(*CARD_INCLUDES).find(@order.id)
      tenant_id = @order.tenant_id
      target_column = column_for(@order.status)
      source_column = column_for(resolve_old_status)

      if source_column && source_column != target_column
        Turbo::StreamsChannel.broadcast_remove_to(
          stream_for(tenant_id),
          target: dom_id
        )
      end

      if target_column
        if source_column == target_column
          Turbo::StreamsChannel.broadcast_replace_to(
            stream_for(tenant_id),
            target: dom_id,
            partial: "barista/dashboard/order_card",
            locals: { order: @order }
          )
        else
          Turbo::StreamsChannel.broadcast_append_to(
            stream_for(tenant_id),
            target: target_column,
            partial: "barista/dashboard/order_card",
            locals: { order: @order }
          )
        end
      end

      broadcast_counts(tenant_id)
      BroadcastTvColumnsJob.perform_later(tenant_id)
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.warn("[Barista::OrderBoardBroadcaster] cable unavailable: #{e.class} #{e.message}")
    end

    private

    def dom_id
      "order_#{@order.id}"
    end

    def stream_for(tenant_id)
      "orders_#{tenant_id}"
    end

    def resolve_old_status
      return @old_status if @old_status.present?

      @order.order_status_logs.order(created_at: :desc).second&.status_to || "accepted"
    end

    def column_for(status)
      case status.to_s
      when "accepted" then "orders-new"
      when "preparing" then "orders-preparing"
      when "ready" then "orders-ready"
      end
    end

    def broadcast_counts(tenant_id)
      raw = Order.for_barista_board(tenant_id)
                 .where(status: %w[accepted preparing ready])
                 .group(:status)
                 .count
      counts = {
        new: raw["accepted"].to_i,
        preparing: raw["preparing"].to_i,
        ready: raw["ready"].to_i
      }

      %i[new preparing ready].each do |type|
        Turbo::StreamsChannel.broadcast_replace_to(
          stream_for(tenant_id),
          target: "count-#{type}",
          partial: "barista/dashboard/count_badge",
          locals: { count: counts[type], type: type.to_s }
        )
      end
    end
  end
end
