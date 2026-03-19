module Barista
  class ReportsController < BaseController
    def index
      @shift = current_shift
      # Заглушка для отчётов - пока просто показываем статистику смены
      if @shift
        @orders_count = Order.for_current_tenant.where(created_at: @shift.opened_at..Time.current).count
        @revenue = Payment.joins(:order)
                         .where(orders: { tenant_id: Current.tenant_id, cash_shift_id: @shift.id })
                         .where(status: 'succeeded')
                         .sum(:amount)
        @average_check = @orders_count > 0 ? (@revenue / @orders_count).round(2) : 0
      end
    end
  end
end
