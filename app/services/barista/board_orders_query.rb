# frozen_string_literal: true

module Barista
  # FIFO-очередь заказов на табло бариста (created_at ASC).
  class BoardOrdersQuery
    INCLUDES = [:order_items, :order_status_logs, :customer, :payments].freeze
    LIMIT = 50
    COLUMN_DOM_IDS = {
      "accepted" => "orders-new",
      "preparing" => "orders-preparing",
      "ready" => "orders-ready"
    }.freeze

    def self.column_dom_id(status)
      COLUMN_DOM_IDS[status.to_s]
    end

    def self.for_column(tenant_id:, status:)
      Order.for_barista_board(tenant_id)
           .where(status: status.to_s)
           .includes(*INCLUDES)
           .order(created_at: :asc)
           .limit(LIMIT)
    end
  end
end
