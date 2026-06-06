# frozen_string_literal: true

module Health
  # Проверка здоровья точки (tenant) по всем компонентам.
  # Результат — хэш с status (ok/warning/error), message и details для каждого чек-бокса.
  class TenantChecker
    RECENT_WINDOW = 1.hour
    RECENT_WINDOW_LONG = 24.hours
    PENDING_PAYMENT_STUCK = 30.minutes

    def initialize(tenant, window: RECENT_WINDOW, window_long: RECENT_WINDOW_LONG, include_events: false)
      @tenant = tenant
      @window = window
      @window_long = window_long
      @since = Time.current - window
      @since_long = Time.current - window_long
      @include_events = include_events
    end

    def call
      result = {
        tenant_id: @tenant.id,
        tenant_name: @tenant.name,
        tenant_slug: @tenant.slug,
        tenant_status: @tenant.status,
        checks: {
          cash_register: check_cash_register,
          orders: check_orders,
          queue: check_queue,
          pending_payment: check_pending_payment,
          kiosk: check_kiosk,
          shop_vitrina: check_shop_vitrina,
          app: check_app,
          payments: check_payments,
          inventory: check_inventory,
          failed_payments: check_failed_payments
        },
        overall: overall_status
      }
      result[:recent_events] = recent_audit_events if @include_events
      result
    end

    private

    def check_cash_register
      open_shift = CashShift.where(tenant_id: @tenant.id, status: 'open').first
      if open_shift
        {
          status: 'ok',
          message: "Касса открыта с #{I18n.l(open_shift.opened_at, format: :short)}",
          shift_id: open_shift.id,
          opened_at: open_shift.opened_at
        }
      else
        {
          status: 'warning',
          message: 'Нет открытой кассы',
          shift_id: nil
        }
      end
    end

    def check_orders
      count = Order.where(tenant_id: @tenant.id).where('created_at > ?', @since).count
      {
        status: count.positive? ? 'ok' : 'warning',
        message: count.positive? ? "Заказов за последний час: #{count}" : 'Нет заказов за последний час',
        count: count,
        since: @since
      }
    end

    def check_queue
      count = Order.where(tenant_id: @tenant.id)
                  .where(status: %w[accepted preparing ready])
                  .count
      {
        status: 'ok',
        message: "В очереди: #{count} заказов",
        count: count
      }
    end

    def check_kiosk
      devices = Device.where(tenant_id: @tenant.id, device_type: 'kiosk')
      online = devices.select { |d| d.online? }.size
      total = devices.size
      kiosk_orders = Order.where(tenant_id: @tenant.id, source: 'kiosk')
                         .where('created_at > ?', @since)
                         .count
      {
        status: total.positive? ? (online.positive? ? 'ok' : 'warning') : 'ok',
        message: "Киоски: #{online}/#{total} онлайн, заказов за час: #{kiosk_orders}",
        devices_total: total,
        devices_online: online,
        orders_last_hour: kiosk_orders
      }
    end

    def check_pending_payment
      scope = Order.where(tenant_id: @tenant.id, status: 'pending_payment')
      total = scope.count
      stuck_since = Time.current - PENDING_PAYMENT_STUCK
      stuck = scope.where('created_at < ?', stuck_since).count
      status = stuck.positive? ? 'warning' : 'ok'
      {
        status: status,
        message: stuck.positive? ? "Зависших оплат (>30 мин): #{stuck} из #{total}" : "Ожидают оплату: #{total}",
        total: total,
        stuck: stuck,
        stuck_threshold_minutes: PENDING_PAYMENT_STUCK.in_minutes.to_i
      }
    end

    def check_shop_vitrina
      count = Order.where(tenant_id: @tenant.id, source: 'mobile')
                  .where('created_at > ?', @since)
                  .count
      {
        status: 'ok',
        message: "Заказы витрины (mobile) за час: #{count}",
        count: count,
        channel: 'shop_mobile'
      }
    end

    def check_app
      count = Order.where(tenant_id: @tenant.id, source: 'app')
                  .where('created_at > ?', @since)
                  .count
      {
        status: 'ok',
        message: "Заказы приложения за час: #{count}",
        count: count
      }
    end

    def check_payments
      scope = Payment.where(tenant_id: @tenant.id, status: 'succeeded').where('created_at > ?', @since)
      count = scope.count
      amount = scope.sum(:amount)
      {
        status: count.positive? ? 'ok' : 'warning',
        message: "Оплат за час: #{count} на #{amount} #{@tenant.currency}",
        count: count,
        amount: amount.to_f
      }
    end

    def check_inventory
      out = IngredientTenantStock.where(tenant_id: @tenant.id, qty: 0).count
      low = IngredientTenantStock.where(tenant_id: @tenant.id)
                                .where('qty <= min_qty AND min_qty > 0')
                                .count
      status = out.positive? ? 'error' : (low.positive? ? 'warning' : 'ok')
      {
        status: status,
        message: "Нулевых остатков: #{out}, низких: #{low}",
        out_of_stock: out,
        low_stock: low
      }
    end

    def check_failed_payments
      count = Payment.where(tenant_id: @tenant.id, status: 'failed')
                    .where('created_at > ?', @since_long)
                    .count
      recent_events = Shop::PaymentFailureJournal.recent_for_tenant(@tenant.id, since: @since_long, limit: 10)
      {
        status: (count.positive? || recent_events.any?) ? 'warning' : 'ok',
        message: "Неудачных оплат за 24ч: #{count}",
        count: count,
        recent_events: recent_events
      }
    end

    def overall_status
      statuses = collect_statuses
      return 'error' if statuses.include?('error')
      return 'warning' if statuses.include?('warning')

      'ok'
    end

    def collect_statuses
      %i[cash_register orders queue pending_payment kiosk shop_vitrina app payments inventory failed_payments].map do |key|
        send("check_#{key}")[:status]
      end
    end

    def recent_audit_events(limit: 20)
      AdminAuditLog
        .for_tenant(@tenant.id)
        .where('created_at >= ?', @since_long)
        .recent
        .limit(limit)
        .map do |log|
          {
            id: log.id,
            at: log.created_at.iso8601,
            action: log.action,
            entity_type: log.entity_type,
            entity_id: log.entity_id,
            actor_id: log.actor_id,
            details: log.details
          }
        end
    end
  end
end
