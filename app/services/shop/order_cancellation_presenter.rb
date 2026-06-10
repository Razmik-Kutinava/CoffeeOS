# frozen_string_literal: true

module Shop
  # Метаданные отмены для API витрины и WebSocket (B1.1).
  module OrderCancellationPresenter
    STAFF_MESSAGE = "Заказ отменён исполнителем. Средства будут возвращены в течение 3 рабочих дней"
    GUEST_MESSAGE = "Заказ отменён"

    module_function

    def meta_for(order)
      return { can_cancel: order.guest_can_cancel? } unless order.cancelled?

      by = cancelled_by(order)
      {
        can_cancel: false,
        cancelled_by: by,
        cancel_message: cancel_message_for(by)
      }
    end

    def cancelled_by(order)
      log = cancellation_log(order)
      case log&.source
      when "barista" then "staff"
      when "customer" then "guest"
      else "system"
      end
    end

    def cancel_message_for(cancelled_by)
      cancelled_by == "staff" ? STAFF_MESSAGE : GUEST_MESSAGE
    end

    def cancellation_log(order)
      order.order_status_logs.where(status_to: "cancelled").order(created_at: :desc).first
    end
  end
end
