# frozen_string_literal: true

module Shop
  # Маппинг статуса заказа/платежа → PENDING|CONFIRMED|REJECTED|CANCELED (ТЗ CODE:BLACK).
  class PaymentStatusPresenter
    def self.call(order)
      new(order).call
    end

    def initialize(order)
      @order = order
    end

    def call
      {
        order_id: @order.id,
        status: mapped_status
      }
    end

    private

    def mapped_status
      return "CANCELED" if @order.cancelled?
      return "CONFIRMED" if order_paid_or_progressing?

      payment = latest_payment
      return "REJECTED" if payment&.failed?
      return "CONFIRMED" if payment&.succeeded?

      "PENDING"
    end

    def order_paid_or_progressing?
      @order.accepted? || @order.preparing? || @order.ready? || @order.issued? || @order.closed?
    end

    def latest_payment
      @order.payments.max_by(&:created_at)
    end
  end
end
