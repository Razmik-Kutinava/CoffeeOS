module Manager
  class CloseWizardController < BaseController
    def show
      if shift_manager?
        current_shift = current_cash_shift
        unless current_shift
          redirect_to manager_shifts_path, alert: "Нет открытой смены"
          return
        end

        unless current_shift.id.to_s == params[:id].to_s
          redirect_to manager_shift_path(current_shift), alert: "Недоступно"
          return
        end

        @shift = current_shift
      else
        @shift = CashShift.for_current_tenant.find(params[:id])
      end

      @pending_payments = Payment.for_current_tenant.includes(:order).joins(:order).where(orders: { cash_shift_id: @shift.id }).pending_or_processing.limit(50)
      @failed_receipts = FiscalReceipt.for_current_tenant.includes(:payment).joins(:order).where(orders: { cash_shift_id: @shift.id }, status: "failed").limit(50)
      @pending_refunds = Refund.for_current_tenant.includes(:payment, :order).joins(:order).where(orders: { cash_shift_id: @shift.id }, status: "pending").limit(50)

      cash_payments_sum = Payment.for_current_tenant.joins(:order)
        .where(orders: { cash_shift_id: @shift.id }, method: "cash", status: "succeeded")
        .sum(:amount)

      deposits = ShiftCashOperation.for_current_tenant.where(shift_id: @shift.id, operation_type: "deposit").sum(:amount)
      withdrawals = ShiftCashOperation.for_current_tenant.where(shift_id: @shift.id, operation_type: "withdrawal").sum(:amount)

      @expected_cash = (@shift.opening_cash || 0) + cash_payments_sum + deposits - withdrawals
    end

    def update
      if shift_manager?
        current_shift = current_cash_shift
        unless current_shift
          redirect_to manager_shifts_path, alert: "Нет открытой смены"
          return
        end

        unless current_shift.id.to_s == params[:id].to_s
          redirect_to manager_shift_path(current_shift), alert: "Недоступно"
          return
        end

        @shift = current_shift
      else
        @shift = CashShift.for_current_tenant.find(params[:id])
      end

      closing_cash = params[:closing_cash].to_f
      pending_payments = Payment.for_current_tenant.joins(:order)
        .where(orders: { cash_shift_id: @shift.id })
        .pending_or_processing

      failed_receipts = FiscalReceipt.for_current_tenant.joins(:order)
        .where(orders: { cash_shift_id: @shift.id }, status: "failed")

      pending_refunds = Refund.for_current_tenant.joins(:order)
        .where(orders: { cash_shift_id: @shift.id }, status: "pending")

      if pending_payments.exists? || failed_receipts.exists? || pending_refunds.exists?
        redirect_to manager_close_shift_path(@shift),
          alert: "Нельзя закрыть смену: есть блокеры (платежи/чеки/возвраты)."
        return
      end

      @shift.close!(current_user, closing_cash)

      redirect_to manager_shift_path(@shift), notice: "Смена закрыта"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to manager_close_shift_path(@shift), alert: e.record.errors.full_messages.join(", ")
    end
  end
end

