# frozen_string_literal: true

module Shop
  # Отмена заказа гостем с экрана статуса (B1.1 / #40):
  # pending_payment — локально через journal;
  # accepted + succeeded — /v2/Cancel → payment refunded;
  # failed/refunded без succeeded — отказ.
  class GuestOrderCancellationService
    class Error < StandardError; end

    GUEST_REASON = "Гость отменил заказ"
    REFUND_UNAVAILABLE = "Автовозврат недоступен. Пожалуйста, обратитесь в поддержку."

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
      # A6 / Quick Repeat: refresh (bust+write), не только delete — гонка с poll frequent
      Shop::CustomerFrequentProductsService.refresh_cache!(
        tenant_id: @tenant_id,
        customer_id: order.customer_id
      )
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
      succeeded = @order.payments.find_by(status: :succeeded)

      if refundable_via_tbank?(succeeded)
        refund_succeeded_via_tbank!(succeeded, old_status: old_status)
      elsif succeeded
        # cash / без PaymentId — локальная отмена, банк не трогаем
        persist_cancelled!(old_status: old_status)
      elsif @order.payments.where(status: %w[failed refunded partially_refunded]).exists?
        raise Error, REFUND_UNAVAILABLE
      else
        persist_cancelled!(old_status: old_status)
      end
    end

    def refundable_via_tbank?(payment)
      payment.present? && payment.provider_payment_id.present?
    end

    # Сначала банк (без тихого cancel при ошибке), затем БД.
    def refund_succeeded_via_tbank!(payment, old_status:)
      response = Payments::TbankAdapter.new.cancel_payment(
        payment_id: payment.provider_payment_id
      )

      ActiveRecord::Base.transaction do
        payment.update!(status: :refunded)
        Refund.create!(
          tenant_id: @tenant_id,
          payment_id: payment.id,
          order_id: @order.id,
          amount: payment.amount,
          reason: GUEST_REASON,
          status: :succeeded,
          provider_refund_id: response["PaymentId"].presence || payment.provider_payment_id
        )
        persist_cancelled!(old_status: old_status)
      end
    rescue Payments::TbankAdapter::ApiError, Payments::TbankAdapter::Error => e
      Rails.logger.warn(
        "[GuestOrderCancellation] Cancel failed order=#{@order.id} " \
        "payment=#{payment.id} #{e.class}: #{e.message}"
      )
      raise Error, REFUND_UNAVAILABLE
    end

    def persist_cancelled!(old_status:)
      ActiveRecord::Base.transaction(requires_new: true) do
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
