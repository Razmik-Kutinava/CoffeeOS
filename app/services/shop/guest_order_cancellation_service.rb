# frozen_string_literal: true

module Shop
  # Отмена заказа гостем с экрана статуса (B1.1): pending_payment или accepted.
  class GuestOrderCancellationService
    class Error < StandardError; end

    GUEST_REASON = "Гость отменил заказ"

    def initialize(order:, session:, tenant_id:, request_id: nil)
      @order = order
      @session = session
      @tenant_id = tenant_id
      @request_id = request_id
    end

    def call!
      unless @order.guest_can_cancel?
        raise Error, guest_cancel_denied_message
      end

      old_status = @order.status

      if @order.pending_payment?
        cancel_pending_payment!
      else
        cancel_accepted!(old_status: old_status)
      end

      Shop::PendingOrderSession.clear!(@session, @tenant_id)

      order = @order.reload
      Shop::GuestOrderBroadcaster.call(order: order, old_status: old_status)
      if old_status != "pending_payment"
        Barista::OrderBoardBroadcaster.call(order: order, old_status: old_status)
      end

      order
    end

    private

    def guest_cancel_denied_message
      if @order.status.in?(%w[preparing ready])
        "Невозможно отменить заказ, он уже готовится"
      else
        "Невозможно отменить заказ"
      end
    end

    def cancel_pending_payment!
      payment = @order.payments.find_by(status: :pending) || @order.payments.order(created_at: :desc).first
      Shop::PaymentFailureJournal.record!(
        order: @order,
        payment: payment,
        reason: :guest_order_cancel,
        source: :customer,
        details: { trigger: "guest_cancel_api" },
        request_id: @request_id
      )
    end

    def cancel_accepted!(old_status:)
      ActiveRecord::Base.transaction do
        @order.update!(
          status: :cancelled,
          cancel_reason: GUEST_REASON,
          cancel_stage: old_status
        )

        OrderStatusLog.create!(
          order_id: @order.id,
          status_from: old_status,
          status_to: "cancelled",
          source: "customer",
          comment: GUEST_REASON
        )

        AdminAuditLog.log(
          action: "shop_order_cancelled",
          actor: nil,
          entity: @order,
          tenant_id: @tenant_id,
          details: {
            order_number: @order.order_number,
            cancel_stage: old_status,
            final_amount: @order.final_amount.to_f,
            channel: "shop_mobile"
          },
          request_id: @request_id
        )
      end
    end
  end
end
