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

      if preparing_count.positive?
        notify_carryover!(preparing_count)
      end

      Barista::OrderBoardBroadcaster.broadcast_carryover(tenant_id: @tenant_id)

      @shift.reload
    end

    private

    # T-Bank Cancel необратим — сначала все вызовы банка, затем одна транзакция БД + close!.
    # При ошибке на N-м заказе — сверяем БД с уже успешными Cancel (reconcile), смену не закрываем.
    def refund_ready_orders!(ready_orders)
      bank_completed = []
      current_order = nil

      ready_orders.each do |order|
        current_order = order
        succeeded = order.payments.find_by(status: :succeeded)
        response = nil

        if refundable_via_tbank?(succeeded)
          response = Payments::TbankAdapter.new.cancel_payment(
            payment_id: succeeded.provider_payment_id
          )
        end

        bank_completed << { order: order, payment: succeeded, response: response }
      end

      persist_ready_entries_and_close!(bank_completed)
    rescue Payments::TbankAdapter::ApiError, Payments::TbankAdapter::Error
      persist_ready_entries!(bank_completed) if bank_completed.any?
      raise Error, "Не удалось вернуть оплату по заказу #{current_order&.order_number}. Смена не закрыта."
    end

    def persist_ready_entries_and_close!(entries)
      ActiveRecord::Base.transaction do
        write_ready_entries!(entries)
        @shift.close!(@closed_by, @closing_cash)
      end
    end

    def persist_ready_entries!(entries)
      ActiveRecord::Base.transaction do
        write_ready_entries!(entries)
      end
    end

    def write_ready_entries!(entries)
      entries.each do |entry|
        if entry[:payment] && entry[:response]
          entry[:payment].update!(status: :refunded)
          Refund.create!(
            tenant_id: @tenant_id,
            payment_id: entry[:payment].id,
            order_id: entry[:order].id,
            amount: entry[:payment].amount,
            reason: READY_CANCEL_REASON,
            status: :succeeded,
            provider_refund_id: entry[:response]["PaymentId"].presence || entry[:payment].provider_payment_id
          )
        end

        persist_system_cancelled!(entry[:order], old_status: "ready")
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
