# frozen_string_literal: true

module Barista
  # Live-обновление канбан-табло барista через Turbo Streams / Solid Cable.
  class OrderBoardBroadcaster
    BOARD_STATUSES = %w[accepted preparing ready].freeze

    def self.call(order:, old_status: nil)
      new(order: order, old_status: old_status).call
    end

    def initialize(order:, old_status: nil)
      @order = order
      @old_status = old_status
    end

    def call
      tenant_id = @order.tenant_id
      resync_columns(tenant_id, affected_statuses)
      broadcast_counts(tenant_id)
      BroadcastTvColumnsJob.perform_later(tenant_id)
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.warn("[Barista::OrderBoardBroadcaster] cable unavailable: #{e.class} #{e.message}")
    end

    private

    def affected_statuses
      old_s = resolve_old_status
      new_s = @order.status.to_s
      [old_s, new_s].select { |s| BOARD_STATUSES.include?(s) }.uniq
    end

    def resolve_old_status
      return @old_status.to_s if @old_status.present?

      @order.order_status_logs.order(created_at: :desc).second&.status_to.to_s.presence || "accepted"
    end

    def resync_columns(tenant_id, statuses)
      statuses.each do |status|
        column_id = BoardOrdersQuery.column_dom_id(status)
        next unless column_id

        Turbo::StreamsChannel.broadcast_replace_to(
          stream_for(tenant_id),
          target: column_id,
          partial: "barista/dashboard/orders_column",
          locals: {
            column_id: column_id,
            orders: Barista::BoardOrdersQuery.for_column(tenant_id: tenant_id, status: status)
          }
        )
      end
    end

    def stream_for(tenant_id)
      "orders_#{tenant_id}"
    end

    def broadcast_counts(tenant_id)
      raw = BoardOrdersQuery.board_scope(tenant_id: tenant_id)
                            .where(status: BOARD_STATUSES)
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
