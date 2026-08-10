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
      payment = latest_payment
      payload = {
        order_id: @order.id,
        status: mapped_status(payment)
      }
      code = error_code_for(payment)
      payload[:error_code] = code if code.present?
      payload
    end

    private

    def mapped_status(payment = latest_payment)
      return "CANCELED" if @order.cancelled?
      return "CONFIRMED" if order_paid_or_progressing?

      return "REJECTED" if payment&.failed?
      return "CONFIRMED" if payment&.succeeded?

      "PENDING"
    end

    def error_code_for(payment)
      return nil unless payment&.failed?

      data = payment.provider_data
      return nil unless data.is_a?(Hash)

      code = data["ErrorCode"].presence || data["error_code"].presence
      code = code.to_s.strip
      return nil if code.blank? || code == "0"

      code
    end

    def order_paid_or_progressing?
      @order.accepted? || @order.preparing? || @order.ready? || @order.issued? || @order.closed?
    end

    def latest_payment
      @order.payments.max_by(&:created_at)
    end
  end
end
