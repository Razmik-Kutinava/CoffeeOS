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
      failed_payments: "Отказы оплаты"
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
  end
end
