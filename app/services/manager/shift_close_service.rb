# frozen_string_literal: true

module Manager
  # Закрытие смены: auto-cancel+refund ready, carryover preparing, уведомления.
  class ShiftCloseService
    class Error < StandardError; end

    READY_CANCEL_REASON = "Смена закрыта, заказ не забран"

    def self.call!(shift:, closed_by:, closing_cash:, request_id: nil)
      new(shift: shift, closed_by: closed_by, closing_cash: closing_cash, request_id: request_id).call!
    end

    def initialize(shift:, closed_by:, closing_cash:, request_id: nil)
      @shift = shift
      @closed_by = closed_by
      @closing_cash = closing_cash
      @request_id = request_id
      @tenant_id = shift.tenant_id
    end

    def call!
      raise Error, "Смена уже закрыта" unless @shift.open?

      ready_orders = @shift.orders.where(status: "ready").includes(:payments).to_a
      preparing_count = @shift.orders.where(status: "preparing").count

      refund_ready_orders!(ready_orders)
      @shift.close!(@closed_by, @closing_cash)

      if preparing_count.positive?
        notify_carryover!(preparing_count)
      end

      Barista::OrderBoardBroadcaster.broadcast_carryover(tenant_id: @tenant_id)

      @shift.reload
    end

    private

    # Каждый ready обрабатывается отдельно; сбой T-Bank не блокирует close!.
    def refund_ready_orders!(ready_orders)
      ready_orders.each do |order|
        process_ready_order!(order)
      end
    end

    def process_ready_order!(order)
      succeeded = order.payments.find_by(status: :succeeded)

      if refundable_via_tbank?(succeeded)
        response = Payments::TbankAdapter.new.cancel_payment(
          payment_id: succeeded.provider_payment_id
        )
        persist_ready_refund_and_cancel!(order, payment: succeeded, response: response)
      else
        persist_system_cancelled!(order, old_status: "ready")
      end
    rescue Payments::TbankAdapter::ApiError, Payments::TbankAdapter::Error => e
      notify_refund_failure!(order, payment: succeeded, error: e)
    end

    def persist_ready_refund_and_cancel!(order, payment:, response:)
      ActiveRecord::Base.transaction do
        payment.update!(status: :refunded)
        Refund.create!(
          tenant_id: @tenant_id,
          payment_id: payment.id,
          order_id: order.id,
          amount: payment.amount,
          reason: READY_CANCEL_REASON,
          status: :succeeded,
          provider_refund_id: response["PaymentId"].presence || payment.provider_payment_id
        )
        persist_system_cancelled!(order, old_status: "ready")
      end
    end

    def refundable_via_tbank?(payment)
      payment.present? && payment.provider_payment_id.present?
    end

    def persist_system_cancelled!(order, old_status:)
      order.update!(
        status: :cancelled,
        cancel_reason: READY_CANCEL_REASON,
        cancel_stage: old_status
      )

      OrderStatusLog.create!(
        order_id: order.id,
        status_from: old_status,
        status_to: "cancelled",
        source: "system",
        comment: READY_CANCEL_REASON
      )

      AdminAuditLog.log(
        action: "shift_close_order_cancelled",
        actor: @closed_by,
        entity: order,
        tenant_id: @tenant_id,
        details: {
          order_number: order.order_number,
          cancel_stage: old_status,
          final_amount: order.final_amount.to_f,
          cash_shift_id: @shift.id
        },
        request_id: @request_id
      )
    end

    def notify_refund_failure!(order, payment:, error:)
      Rails.logger.warn(
        "[ShiftCloseService] T-Bank refund failed order=#{order.id} " \
        "payment=#{payment&.id} #{error.class}: #{error.message}"
      )

      TelegramAlertJob.perform_later(
        "Не удалось вернуть оплату при закрытии смены: заказ ##{order.order_number}. " \
        "Заказ остаётся ready — обработайте вручную.",
        {
          tenant_id: @tenant_id,
          shift_id: @shift.id,
          order_id: order.id,
          order_number: order.order_number,
          payment_id: payment&.id,
          provider_payment_id: payment&.provider_payment_id,
          error_class: error.class.name,
          error_message: error.message
        }
      )
    end

    def notify_carryover!(count)
      TelegramAlertJob.perform_later(
        "Смена закрыта: #{count} заказ(ов) ещё готовятся — передайте следующей смене.",
        {
          tenant_id: @tenant_id,
          shift_id: @shift.id,
          carryover_preparing_count: count
        }
      )
    end
  end
end
