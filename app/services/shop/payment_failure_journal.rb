# frozen_string_literal: true

module Shop
  # Журнал отказов/ошибок оплаты на витрине → OrderStatusLog + AdminAuditLog.
  # AdminAuditLog.action = shop_payment_failed — стабильный ключ для УК JSON (/health/tenants, позже переименуют).
  class PaymentFailureJournal
    ACTION = "shop_payment_failed"

    REASONS = {
      guest_abandon: "Гость отменил оплату на витрине",
      bank_fail_return: "Возврат с банка без оплаты",
      bank_rejected: "Банк отклонил платёж",
      gateway_init_failed: "Не удалось инициировать оплату"
    }.freeze

    class << self
      def record!(order:, reason:, source: :customer, payment: nil, details: {}, request_id: nil)
        new(
          order: order,
          reason: reason,
          source: source,
          payment: payment,
          details: details,
          request_id: request_id
        ).call!
      end

      def recent_for_tenant(tenant_id, since: 24.hours.ago, limit: 20)
        AdminAuditLog
          .for_tenant(tenant_id)
          .where(action: ACTION)
          .where("created_at >= ?", since)
          .recent
          .limit(limit)
          .map { |row| event_json(row) }
      end

      def event_json(log)
        {
          id: log.id,
          at: log.created_at.iso8601,
          action: log.action,
          order_id: log.entity_id,
          entity_type: log.entity_type,
          reason: log.details["reason"],
          reason_label: log.details["reason_label"],
          source: log.details["source"],
          amount: log.details["final_amount"],
          order_number: log.details["order_number"],
          customer_phone: log.details["customer_phone"],
          payment_id: log.details["payment_id"],
          channel: log.details["channel"]
        }
      end
    end

    def initialize(order:, reason:, source: :customer, payment: nil, details: {}, request_id: nil)
      @order = order
      @reason = reason.to_sym
      @source = source.to_sym
      @payment = payment
      @details = details.stringify_keys
      @request_id = request_id
    end

    def call!
      raise ArgumentError, "unknown reason #{@reason}" unless REASONS.key?(@reason)

      @status_before = @order.status

      ActiveRecord::Base.transaction do
        fail_pending_payments!
        cancel_order_if_needed!
        create_status_log!
        create_audit_log!
      end

      Rails.logger.info(
        "[Shop::PaymentFailureJournal] #{@reason} order=#{@order.id} tenant=#{@order.tenant_id}"
      )
    end

    private

    def fail_pending_payments!
      scope = @order.payments.where(status: :pending)
      scope = scope.where(id: @payment.id) if @payment&.id
      scope.find_each { |p| p.update!(status: :failed) }
    end

    def cancel_order_if_needed!
      return unless @order.pending_payment?

      @order.update!(
        status: :cancelled,
        cancel_reason: REASONS[@reason],
        cancel_stage: "pending_payment"
      )
    end

    def create_status_log!
      return if duplicate_cancel_log?

      OrderStatusLog.create!(
        order_id: @order.id,
        status_from: @status_before,
        status_to: @order.status,
        source: log_source,
        comment: REASONS[@reason]
      )
    end

    def duplicate_cancel_log?
      OrderStatusLog.exists?(
        order_id: @order.id,
        status_to: "cancelled",
        comment: REASONS[@reason],
        source: log_source.to_s
      )
    end

    def create_audit_log!
      AdminAuditLog.log(
        action: ACTION,
        actor: nil,
        entity: @order,
        tenant_id: @order.tenant_id,
        details: audit_details,
        request_id: @request_id
      )
    end

    def log_source
      @source == :payment_callback ? :payment_callback : :customer
    end

    def audit_details
      payment = @payment || @order.payments.order(created_at: :desc).first
      customer = @order.customer_id && MobileCustomer.find_by(id: @order.customer_id)

      {
        reason: @reason.to_s,
        reason_label: REASONS[@reason],
        source: log_source.to_s,
        channel: "shop_mobile",
        order_number: @order.order_number,
        final_amount: @order.final_amount.to_f,
        order_status: @order.status,
        payment_id: payment&.id,
        payment_method: payment&.method,
        payment_provider: payment&.provider,
        customer_phone: customer&.phone
      }.merge(@details)
    end
  end
end
