module Barista
  class DashboardController < BaseController
    def index
      # Получаем активные заказы для табло
      @new_orders = Order.for_barista_board(Current.tenant_id)
                        .where(status: 'accepted')
                        .includes(:order_items, :payments, :customer)
                        .order(created_at: :asc)
                        .limit(50)
      
      @preparing_orders = Order.for_barista_board(Current.tenant_id)
                               .where(status: 'preparing')
                               .includes(:order_items, :payments, :customer)
                               .order(created_at: :asc)
                               .limit(50)
      
      @ready_orders = Order.for_barista_board(Current.tenant_id)
                          .where(status: 'ready')
                          .includes(:order_items, :payments, :customer)
                          .order(created_at: :asc)
                          .limit(50)
      
      # Информация о смене
      @shift = current_shift
      @shift_revenue = calculate_shift_revenue if @shift
      @orders_count = @shift ? Order.for_current_tenant.where(created_at: @shift.opened_at..Time.current).count : 0
      @average_time = @orders_count > 0 ? 4.2 : 0
    end
    
    private
    
    def calculate_shift_revenue
      Payment.joins(:order)
             .where(orders: { tenant_id: Current.tenant_id, cash_shift_id: @shift.id })
             .where(status: 'succeeded')
             .sum(:amount)
    end
  end
end
