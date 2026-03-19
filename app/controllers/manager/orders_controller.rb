module Manager
  class OrdersController < BaseController
    def index
      scope = Order.for_current_tenant.order(created_at: :desc)
      scope = scope.where(status: params[:status]) if params[:status].present?

      if shift_manager?
        shift = current_cash_shift
        return @orders = [] unless shift
        scope = scope.where(cash_shift_id: shift.id)
      end

      @orders = scope.limit(200)
    end

    def show
      if shift_manager?
        shift = current_cash_shift
        return redirect_to(manager_orders_path, alert: "Нет открытой смены") unless shift

        @order = Order.for_current_tenant.where(cash_shift_id: shift.id).find(params[:id])
      else
        @order = Order.for_current_tenant.find(params[:id])
      end
      @items = @order.order_items
      @payments = Payment.for_current_tenant.where(order_id: @order.id).order(created_at: :desc)
      @refunds = Refund.for_current_tenant.where(order_id: @order.id).order(created_at: :desc)
      @fiscal_receipts = FiscalReceipt.for_current_tenant.where(order_id: @order.id).order(created_at: :desc)
    end
  end
end

