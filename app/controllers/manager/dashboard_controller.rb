module Manager
  class DashboardController < BaseController
    def show
      @tenant = current_tenant

      # MVP: быстрые метрики для офиса. Умные расчёты (health/incidents) добавим следующим шагом.
      @recent_orders = Order.for_current_tenant.order(created_at: :desc).limit(10)
      @recent_payments = Payment.for_current_tenant.order(created_at: :desc).limit(10)
      @recent_refunds = Refund.for_current_tenant.order(created_at: :desc).limit(10)
      @recent_fiscal = FiscalReceipt.for_current_tenant.order(created_at: :desc).limit(10)

      if shift_manager?
        shift = current_cash_shift
        if shift
          @recent_orders = Order.for_current_tenant.where(cash_shift_id: shift.id).order(created_at: :desc).limit(10)
          @recent_payments = Payment.for_current_tenant.joins(:order)
                                       .where(orders: { cash_shift_id: shift.id })
                                       .order(created_at: :desc).limit(10)
          @recent_refunds = Refund.for_current_tenant.joins(:order)
                                    .where(orders: { cash_shift_id: shift.id })
                                    .order(created_at: :desc).limit(10)
          @recent_fiscal = FiscalReceipt.for_current_tenant.joins(:order)
                                          .where(orders: { cash_shift_id: shift.id })
                                          .order(created_at: :desc).limit(10)
        else
          @recent_orders = []
          @recent_payments = []
          @recent_refunds = []
          @recent_fiscal = []
        end
      end
    end
  end
end

