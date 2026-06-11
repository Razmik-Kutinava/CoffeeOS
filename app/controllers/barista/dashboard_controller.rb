module Barista
  class DashboardController < BaseController
    def index
      tid = Current.tenant_id
      @new_orders = BoardOrdersQuery.for_column(tenant_id: tid, status: "accepted")
      @preparing_orders = BoardOrdersQuery.for_column(tenant_id: tid, status: "preparing")
      @ready_orders = BoardOrdersQuery.for_column(tenant_id: tid, status: "ready")

      @shift = current_shift
      @shift_revenue = calculate_shift_revenue if @shift
      @orders_count = @shift ? Order.for_current_tenant.where(created_at: @shift.opened_at..Time.current).count : 0
      @average_time = @orders_count > 0 ? 4.2 : 0
    end

    private

    def calculate_shift_revenue
      Payment.joins(:order)
             .where(orders: { tenant_id: Current.tenant_id, cash_shift_id: @shift.id })
             .where(status: "succeeded")
             .sum(:amount)
    end
  end
end
