# frozen_string_literal: true

module Barista
  # FIFO-очередь заказов на табло бариста (created_at ASC).
  # Только текущая смена + витрина (cash_shift_id NULL) с момента открытия смены — без лимита «50 старых по всему тенанту».
  class BoardOrdersQuery
    INCLUDES = [ :order_items, :order_status_logs ].freeze
    # B2.1 ревизия 2026-06-12: 6 слотов, только accepted + preparing на табло.
    SLOT_STATUSES = %w[accepted preparing].freeze
    # Заказы с прошлой смены, доступные баристе до issued/cancelled.
    CARRYOVER_STATUSES = SLOT_STATUSES.freeze
    MAX_SLOTS = 6

    COLUMN_DOM_IDS = {
      "accepted" => "orders-new",
      "preparing" => "orders-preparing",
      "ready" => "orders-ready"
    }.freeze

    def self.column_dom_id(status)
      COLUMN_DOM_IDS[status.to_s]
    end

    # Заказы текущей смены + витрина (mobile, cash_shift_id NULL) с opened_at смены.
    # Без фильтра по статусу — для show/update/cancel по id.
    def self.shift_accessible_scope(tenant_id:, cash_shift: :auto)
      shift = resolve_cash_shift(tenant_id, cash_shift)
      base = Order.where(tenant_id: tenant_id)

      if shift
        base.where(shift_accessible_sql, shift_id: shift.id, shift_opened_at: shift.opened_at)
      else
        base.none
      end
    end

    # Заказы, которые бариста должен видеть на табло (без обрезки новых из-за LIMIT).
    def self.board_scope(tenant_id:, cash_shift: :auto)
      shift_accessible_scope(tenant_id: tenant_id, cash_shift: cash_shift)
        .where(status: %w[accepted preparing ready])
    end

    def self.for_slots(tenant_id:, cash_shift: :auto, limit: MAX_SLOTS)
      board_scope(tenant_id: tenant_id, cash_shift: cash_shift)
        .where(status: SLOT_STATUSES)
        .includes(*INCLUDES)
        .order(created_at: :asc)
        .limit(limit)
        .to_a
    end

    def self.slot_counts(tenant_id:, cash_shift: :auto)
      raw = board_scope(tenant_id: tenant_id, cash_shift: cash_shift)
            .where(status: SLOT_STATUSES)
            .group(:status)
            .count
      {
        accepted: raw["accepted"].to_i,
        preparing: raw["preparing"].to_i,
        total: raw.values.sum
      }
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

    def self.shift_accessible_sql
      <<~SQL.squish
        orders.cash_shift_id = :shift_id
        OR (
          orders.cash_shift_id IS NULL
          AND orders.source = 'mobile'
          AND orders.created_at >= :shift_opened_at
        )
        OR (
          orders.status IN ('accepted', 'preparing')
          AND orders.cash_shift_id IS NOT NULL
          AND orders.cash_shift_id <> :shift_id
        )
      SQL
    end

    def self.carryover_preparing_count(tenant_id:, cash_shift: :auto)
      shift = resolve_cash_shift(tenant_id, cash_shift)
      return 0 unless shift

      Order.where(tenant_id: tenant_id, status: CARRYOVER_STATUSES)
           .where.not(cash_shift_id: nil)
           .where.not(cash_shift_id: shift.id)
           .count
    end
    private_class_method :resolve_cash_shift, :shift_accessible_sql
  end
end
