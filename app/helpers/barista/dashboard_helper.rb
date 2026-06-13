# frozen_string_literal: true

module Barista
  module DashboardHelper
    def order_status_start_time(order)
      if order.order_status_logs.loaded?
        order.order_status_logs
             .select { |log| log.status_to == order.status }
             .max_by(&:created_at)&.created_at || order.created_at
      else
        order.order_status_logs.where(status_to: order.status).order(created_at: :desc).pick(:created_at) || order.created_at
      end
    end

    def barista_modifier_tags(item)
      options = item.modifier_options.is_a?(Hash) ? item.modifier_options : {}
      {
        added: Array(options["selected_modifiers"]),
        removed: Array(options["removed_modifiers"])
      }
    end

    def barista_status_button_label(status)
      case status.to_s
      when "accepted" then "ГОТОВИТСЯ"
      when "preparing" then "ГОТОВ"
      when "ready" then "Выдать"
      else ""
      end
    end

    def barista_next_status(status)
      case status.to_s
      when "accepted" then "preparing"
      when "preparing" then "ready"
      when "ready" then "issued"
      end
    end

    def barista_column_dom_id(status)
      Barista::BoardOrdersQuery.column_dom_id(status)
    end

    def barista_board_modifier_label(mods)
      added = Array(mods[:added]).first
      return "+ #{added['name']}" if added.present?

      removed = Array(mods[:removed]).first
      return "БЕЗ #{removed['name']}" if removed.present?

      nil
    end
  end
end
