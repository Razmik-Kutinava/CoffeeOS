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
      session: "Сессия / логин"
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

    KIND_LABELS = {
      "audit" => "Аудит",
      "order_status" => "Статус заказа",
      "check_detail" => "Запись"
    }.freeze

    ACTION_LABELS = {
      "user_login" => "Вход в систему",
      "user_logout" => "Выход из системы",
      "shop_payment_failed" => "Отказ оплаты"
    }.freeze

    def monitoring_kind_label(kind)
      KIND_LABELS[kind.to_s] || kind.to_s
    end

    def monitoring_event_time(at)
      return "—" if at.blank?

      I18n.l(Time.zone.parse(at.to_s), format: :short)
    rescue ArgumentError, TypeError
      at.to_s
    end

    def monitoring_human_summary(event)
      payload = (event[:payload] || {}).with_indifferent_access
      action = payload[:action].presence

      if action.present? && ACTION_LABELS.key?(action)
        base = ACTION_LABELS[action]
        email = payload[:actor_email] || payload[:email]
        return "#{base}: #{email}" if email.present?

        return base
      end

      event[:summary].presence || "Событие"
    end

    PAYMENT_STATUS_COLORS = {
      "succeeded" => "#86efac",
      "pending" => "#fcd34d",
      "processing" => "#fcd34d",
      "failed" => "#fca5a5",
      "refunded" => "#94a3b8",
      "partially_refunded" => "#94a3b8",
      "requires_review" => "#fcd34d"
    }.freeze

    def monitoring_payment_status_badge(status)
      color = PAYMENT_STATUS_COLORS[status.to_s] || "#94a3b8"
      content_tag(
        :span,
        status.to_s,
        style: "display:inline-block;padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;background:#{color}22;color:#{color};border:1px solid #{color}44;"
      )
    end

    def monitoring_online_badge(online)
      if online
        content_tag(
          :span,
          "ОНЛАЙН",
          style: "display:inline-block;padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;background:#86efac22;color:#86efac;border:1px solid #86efac44;"
        )
      else
        content_tag(:span, "офлайн", style: "color:#64748b;font-size:12px;")
      end
    end

    def monitoring_pretty_json(data)
      JSON.pretty_generate(deep_stringify(data))
    rescue StandardError
      data.inspect
    end

    def deep_stringify(obj)
      case obj
      when Hash
        obj.transform_values { |v| deep_stringify(v) }
      when Array
        obj.map { |v| deep_stringify(v) }
      when Time, ActiveSupport::TimeWithZone, Date, DateTime
        obj.iso8601
      else
        obj
      end
    end
  end
end
