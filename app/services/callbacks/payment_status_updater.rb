# frozen_string_literal: true

module Callbacks
  # Обработка callback оплаты: Payment, PaymentStatusLog, перевод Order pending_payment → accepted.
  class PaymentStatusUpdater
    class InvalidStatusError < StandardError; end
    TERMINAL_STATUSES = %w[
      succeeded failed refunded partially_refunded
    ].freeze
    NON_PENDING_PAYMENT_AUDIT = "payment_on_non_pending_order"

    def initialize(payment:, new_status:, provider_data: {}, provider_payment_id: nil, note: nil)
      @payment = payment
      @new_status = new_status.to_s
      @provider_data = provider_data || {}
      @provider_payment_id = provider_payment_id
      @note = note
      @order_for_deduction = nil
    end

    def call!
      unless Payment.statuses.key?(@new_status)
        raise InvalidStatusError, "invalid payment status"
      end

      old_status = @payment.status
      @guest_broadcast_order = nil

      @payment.with_lock do
        downgrade_from_terminal = TERMINAL_STATUSES.include?(old_status) &&
          !TERMINAL_STATUSES.include?(@new_status)

        # Если пришёл устаревший webhook-статус (например AUTHORIZED после CONFIRMED),
        # не даём payment “даунгрейдиться” из terminal-состояния.
        @payment.status = @new_status unless downgrade_from_terminal
        @payment.provider_data = (@payment.provider_data || {}).merge(@provider_data)
        @payment.provider_payment_id = @provider_payment_id if @provider_payment_id.present?
        status_for_paid_at = downgrade_from_terminal ? old_status : @new_status
        @payment.paid_at = Time.current if status_for_paid_at == "succeeded" && @payment.paid_at.blank?
        @payment.save!

        if !downgrade_from_terminal && old_status != @new_status
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
        fail_order_if_rejected!
      end

      # TASK_93-J: Cable/push/APNs enqueue after row lock (R2).
      broadcast_guest_order_if_needed!

      # TASK_93-A: списание после commit оплаты/accepted — склад не откатывает txn денег.
      deduct_inventory_if_needed!

      @payment.reload
    end

    private

    def broadcast_guest_order_if_needed!
      return unless @guest_broadcast_order

      order = @guest_broadcast_order.reload
      Shop::GuestOrderBroadcaster.call(order: order, old_status: "pending_payment")
    end

    def accept_order_if_paid!
      return unless @payment.status == "succeeded"

      # #78: subscription tech-order must not go to barista board; fulfill subscription instead.
      if subscription_intent?
        fulfill_subscription_payment!
        return
      end

      order = @payment.order
      unless order.status == "pending_payment"
        audit_payment_on_non_pending_order!(order)
        return
      end

      order.update!(status: "accepted")
      OrderStatusLog.create!(
        order: order,
        status_from: "pending_payment",
        status_to: "accepted",
        changed_by_id: nil,
        source: "payment_callback",
        comment: "Оплата подтверждена callback"
      )
      order = order.reload
      @order_for_deduction = order
      @guest_broadcast_order = order
      Barista::OrderBoardBroadcaster.call(order: order, old_status: "pending_payment")
      # Quick Repeat: оплаченный заказ меняет частоту покупок — сбрасываем кэш секции «повторить»
      Shop::CustomerFrequentProductsService.bust_cache!(tenant_id: order.tenant_id, customer_id: order.customer_id)
    end

    def deduct_inventory_if_needed!
      return unless @order_for_deduction

      Inventory::OrderRecipeDeduction.call!(order: @order_for_deduction)
    end

    def audit_payment_on_non_pending_order!(order)
      AdminAuditLog.log(
        action: NON_PENDING_PAYMENT_AUDIT,
        actor: nil,
        entity: @payment,
        tenant_id: order.tenant_id,
        details: {
          reason: "needs_manual_refund",
          order_id: order.id,
          order_status: order.status,
          payment_id: @payment.id
        }
      )
      Rails.logger.error(
        "[PaymentStatusUpdater] succeeded on non-pending_payment order=#{order.id} " \
        "status=#{order.status} payment=#{@payment.id} → needs_manual_refund"
      )
      Rails.error.report(
        StandardError.new("payment succeeded on non-pending_payment order"),
        handled: true,
        context: { order_id: order.id, order_status: order.status, payment_id: @payment.id }
      )
    rescue StandardError => e
      Rails.logger.error("[PaymentStatusUpdater] non-pending audit failed: #{e.class}: #{e.message}")
    end

    def subscription_intent?
      data = @payment.provider_data
      return false unless data.is_a?(Hash)

      ActiveModel::Type::Boolean.new.cast(data["subscription_intent"])
    end

    def fulfill_subscription_payment!
      order = @payment.order
      if order.pending_payment? || order.accepted?
        old_status = order.status
        order.update!(status: "closed")
        OrderStatusLog.create!(
          order: order,
          status_from: old_status,
          status_to: "closed",
          changed_by_id: nil,
          source: "payment_callback",
          comment: "Оплата подписки подтверждена callback"
        )
      end
      Subscriptions::PaymentFulfillment.call(payment: @payment.reload)
    end

    def fail_order_if_rejected!
      return unless @payment.status == "failed"
      return unless @payment.order.pending_payment?

      Shop::PaymentFailureJournal.record!(
        order: @payment.order,
        payment: @payment,
        reason: :bank_rejected,
        source: :payment_callback,
        details: {
          trigger: "payment_callback",
          provider_status: @provider_data["Status"],
          note: @note
        }.compact
      )
    end
  end
end
