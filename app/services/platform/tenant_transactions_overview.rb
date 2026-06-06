# frozen_string_literal: true

module Platform
  # Список платежей по точке для УК — сумма, статус, заказ, T-Bank PaymentId (§2A.4).
  class TenantTransactionsOverview
    DEFAULT_WINDOW = Health::TenantChecker::RECENT_WINDOW_LONG
    ROW_LIMIT = 200

    def initialize(tenant, since: nil, status: nil, method: nil)
      @tenant = tenant
      @since = since || (Time.current - DEFAULT_WINDOW)
      @status = status.presence
      @method = method.presence
    end

    def call
      payments = load_payments

      {
        tenant: { id: @tenant.id, name: @tenant.name, slug: @tenant.slug },
        window_since: @since.iso8601,
        filters: { status: @status, method: @method },
        summary: build_summary(payments),
        payments: payments.map { |p| payment_payload(p) },
        failed_events: load_failed_events
      }
    end

    private

    def load_payments
      scope = Payment.where(tenant_id: @tenant.id)
                     .where("created_at >= ?", @since)
                     .includes(:order)
                     .order(created_at: :desc)
                     .limit(ROW_LIMIT)
      scope = scope.where(status: @status) if @status
      scope = scope.where(method: @method) if @method
      scope.to_a
    end

    def build_summary(payments)
      by_status = payments.group_by(&:status).transform_values(&:count)
      succeeded_amount = payments.select { |p| p.status == "succeeded" }.sum { |p| p.amount.to_f }

      {
        total_count: payments.size,
        by_status: by_status,
        succeeded_amount: succeeded_amount,
        currency: @tenant.currency
      }
    end

    def payment_payload(payment)
      order = payment.order
      {
        payment_id: payment.id,
        at: payment.created_at.iso8601,
        paid_at: payment.paid_at&.iso8601,
        order_id: payment.order_id,
        order_number: order&.order_number,
        order_status: order&.status,
        order_source: order&.source,
        amount: payment.amount.to_f,
        status: payment.status,
        method: payment.method,
        provider: payment.provider,
        provider_payment_id: payment.provider_payment_id,
        summary: payment_summary(payment, order)
      }
    end

    def payment_summary(payment, order)
      num = order&.order_number || payment.order_id
      pid = payment.provider_payment_id
      base = "Оплата #{payment.amount} ₽ (#{payment.status}) — заказ #{num}"
      pid.present? ? "#{base}, PaymentId #{pid}" : base
    end

    def load_failed_events
      feed = Health::TenantEventFeed.new(@tenant).call
      feed[:unified_feed].select { |e| e[:check].to_s == "failed_payments" }
    end
  end
end
