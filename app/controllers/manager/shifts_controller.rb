module Manager
  class ShiftsController < BaseController
    def index
      if shift_manager?
        shift = current_cash_shift
        @shifts = shift ? [shift] : []
      else
        @shifts = CashShift.for_current_tenant.recent.limit(200)
      end
    end

    def show
      if shift_manager?
        shift = current_cash_shift
        unless shift && shift.id.to_s == params[:id].to_s
          redirect_to manager_shifts_path, alert: "Недоступно"
          return
        end

        @shift = shift
      else
        @shift = CashShift.for_current_tenant.find(params[:id])
      end

      @orders = Order.for_current_tenant.where(cash_shift_id: @shift.id).order(created_at: :desc).limit(200)
      @payments = Payment.for_current_tenant.joins(:order).where(orders: { cash_shift_id: @shift.id }).order(created_at: :desc).limit(200)
      @cash_ops = ShiftCashOperation.for_current_tenant.where(shift_id: @shift.id).recent.limit(200)
    end
  end
end

