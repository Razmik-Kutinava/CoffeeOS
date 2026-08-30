module Manager
  class IncidentsController < BaseController
    skip_before_action :skip_authorization
    after_action :verify_authorized

    def index
      authorize :incident_dashboard, :index?, policy_class: Manager::IncidentPolicy
      # MVP: инциденты как "виртуальный список" из основных источников.
      # Дальше вынесем в service + scoring + быстрые действия.
      if shift_manager?
        shift = current_cash_shift
        if shift
          @pending_payments = Payment.for_current_tenant.includes(:order).pending_or_processing
                                   .joins(:order)
                                   .where(orders: { cash_shift_id: shift.id })
                                   .order(created_at: :asc)
                                   .limit(50)
          @failed_receipts = FiscalReceipt.for_current_tenant.includes(:payment).where(status: "failed")
                                            .joins(:order)
                                            .where(orders: { cash_shift_id: shift.id })
                                            .order(created_at: :asc)
                                            .limit(50)
          @pending_refunds = Refund.for_current_tenant.includes(:payment, :order).pending
                                     .joins(:order)
                                     .where(orders: { cash_shift_id: shift.id })
                                     .order(created_at: :asc)
                                     .limit(50)
        else
          @pending_payments = []
          @failed_receipts = []
          @pending_refunds = []
        end
      else
        @pending_payments = Payment.for_current_tenant.includes(:order).pending_or_processing.order(created_at: :asc).limit(50)
        @failed_receipts = FiscalReceipt.for_current_tenant.includes(:payment).where(status: "failed").order(created_at: :asc).limit(50)
        @pending_refunds = Refund.for_current_tenant.includes(:payment, :order).pending.order(created_at: :asc).limit(50)
      end

      @offline_devices = Device.for_current_tenant
                                .where("last_seen_at IS NULL OR last_seen_at <= ?", 2.minutes.ago)
                                .order(last_seen_at: :asc)
                                .limit(50)
      @out_of_stock = IngredientTenantStock.for_current_tenant.out_of_stock.includes(:ingredient).limit(50)
      @shop_payment_failures = AdminAuditLog
        .for_tenant(Current.tenant_id)
        .where(action: Shop::PaymentFailureJournal::ACTION)
        .recent
        .limit(50)
        .includes(:tenant)
    end
  end
end
