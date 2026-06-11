# frozen_string_literal: true

module Barista
  # FIFO-очередь заказов на табло бариста (created_at ASC).
  # Только текущая смена + витрина (cash_shift_id NULL) с момента открытия смены — без лимита «50 старых по всему тенанту».
  class BoardOrdersQuery
    INCLUDES = [:order_items, :order_status_logs].freeze
    VITRINA_WITHOUT_SHIFT_HOURS = 24

    COLUMN_DOM_IDS = {
      "accepted" => "orders-new",
      "preparing" => "orders-preparing",
      "ready" => "orders-ready"
    }.freeze

    def self.column_dom_id(status)
      COLUMN_DOM_IDS[status.to_s]
    end

    # Заказы, которые бариста должен видеть на табло (без обрезки новых из-за LIMIT).
    def self.board_scope(tenant_id:, cash_shift: :auto)
      shift = resolve_cash_shift(tenant_id, cash_shift)
      base = Order.for_barista_board(tenant_id)

      if shift
        base.where(
          <<~SQL.squish,
            orders.cash_shift_id = :shift_id
            OR (
              orders.cash_shift_id IS NULL
              AND orders.source = 'mobile'
              AND orders.created_at >= :shift_opened_at
            )
          SQL
          shift_id: shift.id,
          shift_opened_at: shift.opened_at
        )
      else
        # Смена закрыта — только недавняя витрина без привязки к смене (POS без смены не создаётся).
        since = VITRINA_WITHOUT_SHIFT_HOURS.hours.ago
        base.where(cash_shift_id: nil, source: "mobile")
            .where("orders.created_at >= ?", since)
      end
    end

    def self.for_column(tenant_id:, status:, cash_shift: :auto)
      board_scope(tenant_id: tenant_id, cash_shift: cash_shift)
        .where(status: status.to_s)
        .includes(*INCLUDES)
        .order(created_at: :asc)
    end

    def self.column_count(tenant_id:, status:, cash_shift: :auto)
      board_scope(tenant_id: tenant_id, cash_shift: cash_shift)
        .where(status: status.to_s)
        .count
    end

    def self.resolve_cash_shift(tenant_id, cash_shift)
      return cash_shift if cash_shift.is_a?(CashShift)
      return nil if cash_shift.nil?

      CashShift.find_by(tenant_id: tenant_id, status: "open")
    end
    private_class_method :resolve_cash_shift
  end
end
