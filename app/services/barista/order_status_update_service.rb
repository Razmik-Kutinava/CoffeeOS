# frozen_string_literal: true

module Barista
  # Смена статуса заказа на POS: update Order + OrderStatusLog в одной транзакции.
  class OrderStatusUpdateService
    class OrderStatusUpdateError < StandardError; end

    def initialize(order:, new_status:, user_id:, comment: nil)
      @order = order
      @new_status = new_status.to_s
      @user_id = user_id
      @comment = comment
    end

    def call!
      unless @order.can_change_status?
        raise OrderStatusUpdateError, "Нельзя изменить статус"
      end

      unless @order.can_transition_to?(@new_status)
        raise OrderStatusUpdateError, "Недопустимый переход статуса"
      end

      old_status = @order.status

      ActiveRecord::Base.transaction do
        @order.update!(status: @new_status)

        OrderStatusLog.create!(
          order_id: @order.id,
          status_from: old_status,
          status_to: @new_status,
          changed_by_id: @user_id,
          device_id: nil,
          source: "barista",
          comment: @comment
        )
      end

      { order: @order.reload, old_status: old_status }
    end
  end
end
