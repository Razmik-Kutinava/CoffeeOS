# frozen_string_literal: true

module Platform
  module MonitoringHelper
    CHECK_LABELS = {
      cash_register: "Касса",
      orders: "Заказы (час)",
      queue: "Очередь",
      pending_payment: "Ожидание оплаты",
      kiosk: "Киоски",
      shop_vitrina: "Витрина (mobile)",
      app: "Приложение",
      payments: "Оплаты (час)",
      inventory: "Склад",
      failed_payments: "Отказы оплаты",
      session: "Сессия / логин",
    }.freeze

    def monitoring_status_color(status)
      case status.to_s
      when "ok" then "#86efac"
      when "warning" then "#fcd34d"
      when "error" then "#fca5a5"
      else "#94a3b8"
      end
    end

    def monitoring_status_badge(status)
      color = monitoring_status_color(status)
      content_tag(
        :span,
        status.to_s.upcase,
        style: "display:inline-block;padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;background:#{color}22;color:#{color};border:1px solid #{color}44;"
      )
    end

    def monitoring_check_label(key)
      CHECK_LABELS[key.to_sym] || key.to_s.humanize
    end

    COLUMN_LABELS = {
      "at" => "Время",
      "order_number" => "Заказ",
      "order_id" => "ID заказа",
      "status" => "Статус",
      "source" => "Источник",
      "final_amount" => "Сумма",
      "customer_id" => "Клиент",
      "stuck" => "Завис",
      "waiting_minutes" => "Мин ожид.",
      "amount" => "Сумма",
      "method" => "Способ",
      "provider" => "Провайдер",
      "provider_payment_id" => "PaymentId",
      "payment_id" => "ID платежа",
      "reason_label" => "Причина",
      "reason" => "Причина",
      "ingredient_name" => "Ингредиент",
      "level" => "Уровень",
      "qty" => "Остаток",
      "min_qty" => "Мин.",
      "name" => "Имя",
      "online" => "Онлайн",
      "last_seen_at" => "Last seen",
      "record_type" => "Тип",
      "shift_id" => "Смена",
      "opened_at" => "Открыта",
      "closed_at" => "Закрыта",
      "opened_by_id" => "Кто открыл"
    }.freeze

    def monitoring_column_label(key)
      COLUMN_LABELS[key.to_s] || key.to_s.humanize
    end

    def monitoring_cell_value(value)
      case value
      when true then "да"
      when false then "нет"
      when nil then "—"
      when Time, ActiveSupport::TimeWithZone then I18n.l(value, format: :short)
      else value.to_s.truncate(48)
      end
    end
  end
end
