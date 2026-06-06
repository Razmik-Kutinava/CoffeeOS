# frozen_string_literal: true

module Health
  # Детальные строки под каждой проверкой + единая лента для UI и ИИ-агента.
  class TenantEventFeed
    ROW_LIMIT = 50
    FEED_LIMIT = 100

    def initialize(tenant, since_long: TenantChecker::RECENT_WINDOW_LONG, since_hour: TenantChecker::RECENT_WINDOW)
      @tenant = tenant
      @since_long = Time.current - since_long
      @since_hour = Time.current - since_hour
      @stuck_before = Time.current - TenantChecker::PENDING_PAYMENT_STUCK
    end

    def call
      details = {
        cash_register: cash_register_block,
        orders: orders_hour_block,
        queue: queue_block,
        pending_payment: pending_payment_block,
        kiosk: kiosk_block,
        shop_vitrina: orders_source_block("mobile"),
        app: orders_source_block("app"),
        payments: payments_block,
        inventory: inventory_block,
        failed_payments: failed_payments_block
      }

      {
        check_details: details,
        unified_feed: build_unified_feed(details)
      }
    end

    private

    def cash_register_block
      rows = CashShift.where(tenant_id: @tenant.id)
                      .where("opened_at >= ?", @since_long)
                      .order(opened_at: :desc)
                      .limit(ROW_LIMIT)
                      .map do |shift|
        {
          at: shift.opened_at.iso8601,
          shift_id: shift.id,
          status: shift.status,
          opened_at: shift.opened_at.iso8601,
          closed_at: shift.closed_at&.iso8601,
          opened_by_id: shift.opened_by_id
        }
      end

      block("cash_register", rows, %w[at status opened_at closed_at opened_by_id shift_id])
    end

    def orders_hour_block
      rows = orders_scope.where("created_at >= ?", @since_hour)
                         .order(created_at: :desc)
                         .limit(ROW_LIMIT)
                         .map { |o| order_row(o) }

      block("orders", rows, order_columns)
    end

    def queue_block
      rows = orders_scope.where(status: %w[accepted preparing ready])
                         .order(created_at: :desc)
                         .limit(ROW_LIMIT)
                         .map { |o| order_row(o) }

      block("queue", rows, order_columns)
    end

    def pending_payment_block
      rows = orders_scope.where(status: "pending_payment")
                         .order(created_at: :asc)
                         .limit(ROW_LIMIT)
                         .map do |o|
        order_row(o).merge(
          stuck: o.created_at < @stuck_before,
          waiting_minutes: ((Time.current - o.created_at) / 60).to_i
        )
      end

      block("pending_payment", rows, order_columns + %w[stuck waiting_minutes])
    end

    def kiosk_block
      devices = Device.where(tenant_id: @tenant.id, device_type: "kiosk").order(:name).limit(ROW_LIMIT)
      device_rows = devices.map do |d|
        {
          at: (d.last_seen_at || d.updated_at).iso8601,
          device_id: d.id,
          name: d.name,
          online: d.online?,
          last_seen_at: d.last_seen_at&.iso8601
        }
      end

      order_rows = orders_scope.where(source: "kiosk")
                               .where("created_at >= ?", @since_hour)
                               .order(created_at: :desc)
                               .limit(20)
                               .map { |o| order_row(o).merge(record_type: "order") }

      rows = device_rows.map { |r| r.merge(record_type: "device") } + order_rows
      block("kiosk", rows, %w[record_type at name online last_seen_at order_number status final_amount])
    end

    def orders_source_block(source)
      rows = orders_scope.where(source: source)
                         .where("created_at >= ?", @since_hour)
                         .order(created_at: :desc)
                         .limit(ROW_LIMIT)
                         .map { |o| order_row(o) }

      block(source == "mobile" ? "shop_vitrina" : "app", rows, order_columns)
    end

    def payments_block
      rows = Payment.where(tenant_id: @tenant.id, status: "succeeded")
                    .where("created_at >= ?", @since_hour)
                    .includes(:order)
                    .order(created_at: :desc)
                    .limit(ROW_LIMIT)
                    .map { |p| payment_row(p) }

      block("payments", rows, payment_columns)
    end

    def inventory_block
      stocks = IngredientTenantStock.where(tenant_id: @tenant.id)
                                    .where("qty = 0 OR (qty <= min_qty AND min_qty > 0)")
                                    .includes(:ingredient)
                                    .order(:qty)
                                    .limit(ROW_LIMIT)

      rows = stocks.map do |s|
        {
          at: s.updated_at.iso8601,
          ingredient_id: s.ingredient_id,
          ingredient_name: s.ingredient&.name,
          qty: s.qty.to_f,
          min_qty: s.min_qty.to_f,
          level: s.qty.zero? ? "out" : "low"
        }
      end

      block("inventory", rows, %w[at ingredient_name level qty min_qty ingredient_id])
    end

    def failed_payments_block
      audit_rows = Shop::PaymentFailureJournal.recent_for_tenant(@tenant.id, since: @since_long, limit: ROW_LIMIT)
      payment_rows = Payment.where(tenant_id: @tenant.id, status: "failed")
                            .where("created_at >= ?", @since_long)
                            .includes(:order)
                            .order(created_at: :desc)
                            .limit(ROW_LIMIT)
                            .map { |p| payment_row(p).merge(record_type: "payment") }

      rows = audit_rows.map { |e| e.merge(record_type: "audit") } + payment_rows
      block("failed_payments", rows, %w[record_type at order_number reason_label amount status provider_payment_id])
    end

    def build_unified_feed(details)
      events = []

      details.each do |check_key, detail|
        detail[:rows].each do |row|
          events << {
            at: row[:at] || row["at"],
            kind: "check_detail",
            check: check_key.to_s,
            summary: feed_summary(check_key, row),
            payload: row
          }
        end
      end

      audit_logs = AdminAuditLog.for_tenant(@tenant.id)
                                .where("created_at >= ?", @since_long)
                                .recent
                                .limit(ROW_LIMIT)

      audit_logs.each do |log|
        events << {
          at: log.created_at.iso8601,
          kind: "audit",
          check: audit_check_key(log.action),
          summary: audit_summary(log),
          payload: audit_payload(log)
        }
      end

      status_logs = OrderStatusLog.joins(:order)
                                  .where(orders: { tenant_id: @tenant.id })
                                  .where("order_status_logs.created_at >= ?", @since_long)
                                  .includes(:order)
                                  .order("order_status_logs.created_at DESC")
                                  .limit(ROW_LIMIT)

      status_logs.each do |log|
        events << {
          at: log.created_at.iso8601,
          kind: "order_status",
          check: "orders",
          summary: "Заказ #{log.order&.order_number}: #{log.status_from} → #{log.status_to}",
          payload: {
            order_id: log.order_id,
            order_number: log.order&.order_number,
            status_from: log.status_from,
            status_to: log.status_to,
            source: log.source,
            comment: log.comment,
            changed_by_id: log.changed_by_id
          }
        }
      end

      events
        .select { |e| e[:at].present? }
        .sort_by { |e| e[:at] }
        .reverse
        .first(FEED_LIMIT)
    end

    def feed_summary(check_key, row)
      case check_key.to_sym
      when :pending_payment
        num = row[:order_number] || row["order_number"]
        stuck = row[:stuck] || row["stuck"]
        "Заказ #{num} pending_payment#{stuck ? " (завис)" : ""}"
      when :failed_payments
        row[:reason_label] || row[:status] || "отказ оплаты"
      when :payments
        "Оплата #{row[:amount]} #{row[:status]}"
      when :inventory
        "#{row[:ingredient_name]}: #{row[:level]}"
      when :cash_register
        "Смена #{row[:status]}"
      else
        num = row[:order_number] || row["order_number"]
        num ? "Заказ #{num}" : check_key.to_s
      end
    end

    def audit_check_key(action)
      case action
      when Shop::PaymentFailureJournal::ACTION then "failed_payments"
      when Auth::LoginJournal::ACTION_LOGIN, Auth::LoginJournal::ACTION_LOGOUT then "session"
      else "orders"
      end
    end

    def audit_summary(log)
      case log.action
      when Auth::LoginJournal::ACTION_LOGIN
        "Вход: #{log.details['email']} (#{log.details['user_id']})"
      when Auth::LoginJournal::ACTION_LOGOUT
        "Выход: #{log.details['email']} (#{log.details['user_id']})"
      when Shop::PaymentFailureJournal::ACTION
        log.details["reason_label"] || log.action
      else
        "#{log.action} #{log.entity_type}##{log.entity_id}"
      end
    end

    def audit_payload(log)
      base = {
        action: log.action,
        actor_id: log.actor_id,
        actor_email: log.details["email"],
        actor_name: log.details["name"],
        entity_type: log.entity_type,
        entity_id: log.entity_id,
        user_id: log.details["user_id"],
        role_code: log.details["role_code"]
      }

      if log.action == Shop::PaymentFailureJournal::ACTION
        base.merge(Shop::PaymentFailureJournal.event_json(log))
      else
        base.merge(log.details.symbolize_keys)
      end
    end

    def orders_scope
      Order.where(tenant_id: @tenant.id)
    end

    def order_row(order)
      {
        at: order.created_at.iso8601,
        order_id: order.id,
        order_number: order.order_number,
        status: order.status,
        source: order.source,
        final_amount: order.final_amount.to_f,
        customer_id: order.customer_id,
        created_at: order.created_at.iso8601
      }
    end

    def payment_row(payment)
      {
        at: payment.created_at.iso8601,
        payment_id: payment.id,
        order_id: payment.order_id,
        order_number: payment.order&.order_number,
        amount: payment.amount.to_f,
        status: payment.status,
        method: payment.method,
        provider: payment.provider,
        provider_payment_id: payment.provider_payment_id
      }
    end

    def order_columns
      %w[at order_number status source final_amount order_id customer_id]
    end

    def payment_columns
      %w[at order_number amount status method provider_payment_id payment_id]
    end

    def block(key, rows, columns)
      {
        check: key.to_s,
        columns: columns,
        rows: rows,
        count: rows.size
      }
    end
  end
end
