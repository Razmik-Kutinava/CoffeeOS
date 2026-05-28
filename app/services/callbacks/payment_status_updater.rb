# frozen_string_literal: true

module Callbacks
  # Обработка callback оплаты: Payment, PaymentStatusLog, перевод Order pending_payment → accepted.
  class PaymentStatusUpdater
    class InvalidStatusError < StandardError; end

    def initialize(payment:, new_status:, provider_data: {}, provider_payment_id: nil, note: nil)
      @payment = payment
      @new_status = new_status.to_s
      @provider_data = provider_data || {}
      @provider_payment_id = provider_payment_id
      @note = note
    end

    def call!
      unless Payment.statuses.key?(@new_status)
        raise InvalidStatusError, "invalid payment status"
      end

      old_status = @payment.status

      @payment.with_lock do
        @payment.status = @new_status
        @payment.provider_data = (@payment.provider_data || {}).merge(@provider_data)
        @payment.provider_payment_id = @provider_payment_id if @provider_payment_id.present?
        @payment.paid_at = Time.current if @new_status == "succeeded" && @payment.paid_at.blank?
        @payment.save!

        if old_status != @new_status
          PaymentStatusLog.create!(
            payment: @payment,
            status_from: old_status,
            status_to: @new_status,
            source: "callback",
            note: @note,
            provider_response: @provider_data
          )
        end

        accept_order_if_paid!
      end

      @payment.reload
    end

    private

    def accept_order_if_paid!
      return unless @payment.status == "succeeded"
      return unless @payment.order.status == "pending_payment"

      @payment.order.update!(status: "accepted")
      OrderStatusLog.create!(
        order: @payment.order,
        status_from: "pending_payment",
        status_to: "accepted",
        changed_by_id: nil,
        source: "payment_callback",
        comment: "Оплата подтверждена callback"
      )
      order = @payment.order.reload
      Inventory::OrderRecipeDeduction.call!(order: order)
      Barista::OrderBoardBroadcaster.call(order: order, old_status: "pending_payment")
    end
  end
end
