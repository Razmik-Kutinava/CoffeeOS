module Manager
  class ShiftsController < BaseController
    skip_before_action :skip_authorization
    after_action :verify_authorized

    def index
      authorize CashShift, :index?
      @open_shift = current_cash_shift
      if shift_manager?
        @shifts = @open_shift ? [ @open_shift ] : CashShift.for_current_tenant.recent.limit(20)
      else
        @shifts = CashShift.for_current_tenant.recent.limit(200)
      end
    end

    def create
      authorize CashShift, :create?
      unless shift_manager? || general_manager?
        redirect_to manager_shifts_path, alert: "Открыть смену может менеджер смены или управляющий точки"
        return
      end

      tenant = current_tenant || Tenant.find(Current.tenant_id)
      shift = CashShifts::OpenService.call(
        tenant: tenant,
        opened_by: current_user,
        opening_cash: params[:opening_cash]
      )
      redirect_to manager_shifts_path, notice: "Смена открыта (#{shift.opened_at.strftime('%H:%M')})"
    rescue CashShifts::OpenService::Error => e
      redirect_to manager_shifts_path, alert: e.message
    end

    def show
      if shift_manager?
        shift = current_cash_shift
        unless shift && shift.id.to_s == params[:id].to_s
          authorize CashShift, :show?
          redirect_to manager_shifts_path, alert: "Недоступно"
          return
        end

        @shift = shift
      else
        @shift = CashShift.for_current_tenant.find(params[:id])
      end
      authorize @shift, :show?

      @orders = Order.for_current_tenant.includes(:customer, :order_items).where(cash_shift_id: @shift.id).order(created_at: :desc).limit(200)
      @payments = Payment.for_current_tenant.includes(:order).joins(:order).where(orders: { cash_shift_id: @shift.id }).order(created_at: :desc).limit(200)
      @cash_ops = ShiftCashOperation.for_current_tenant.where(shift_id: @shift.id).recent.limit(200)
    end
  end
end
