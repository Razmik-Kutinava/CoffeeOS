module Barista
  class DashboardController < BaseController
    def index
      authorize Order, :read_board?
      tid = Current.tenant_id
      @shift = current_shift
      @board_orders = BoardOrdersQuery.for_slots(tenant_id: tid, cash_shift: @shift)
      @slot_counts = BoardOrdersQuery.slot_counts(tenant_id: tid, cash_shift: @shift)
      @shift_revenue = calculate_shift_revenue if @shift
      @orders_count = @shift ? Order.for_current_tenant.where(created_at: @shift.opened_at..Time.current).count : 0
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
