module Barista
  class ShiftsController < BaseController
    def show
      @shift = current_shift
      @current_user_obj = current_user
      
      # Сотрудники на смене (read-only для бариста)
      if @shift
        # ShiftStaff связан с Shift, а не с CashShift
        # Показываем только текущего пользователя и того, кто открыл смену
        @shift_staff = []
        
        # Добавляем того, кто открыл смену
        if @shift.opened_by
          @shift_staff << @shift.opened_by unless @shift_staff.any? { |u| u.id == @shift.opened_by.id }
        end
        
        # Добавляем текущего пользователя
        unless @shift_staff.any? { |u| u.id == @current_user_obj.id }
          @shift_staff << @current_user_obj
        end
        
        # Статистика за смену
        @orders_count = Order.for_current_tenant.where(created_at: @shift.opened_at..Time.current).count
        @revenue = Payment.joins(:order)
                         .where(orders: { tenant_id: Current.tenant_id, cash_shift_id: @shift.id })
                         .where(status: 'succeeded')
                         .sum(:amount)
        @average_check = @orders_count > 0 ? (@revenue / @orders_count).round(2) : 0
        
        @payments_by_method = Payment.joins(:order)
                                     .where(orders: { tenant_id: Current.tenant_id, cash_shift_id: @shift.id })
                                     .where(status: 'succeeded')
                                     .group(:method)
                                     .select('method, COUNT(*) as count, SUM(amount) as total')
        
        @cancelled_count = Order.for_current_tenant.where(status: 'cancelled', created_at: @shift.opened_at..Time.current).count
        @refund_count = Payment.joins(:order)
                               .where(orders: { tenant_id: Current.tenant_id, cash_shift_id: @shift.id })
                               .where(status: 'refunded')
                               .count
      else
        # Если смена не открыта, показываем только текущего пользователя
        @shift_staff = [@current_user_obj]
        @orders_count = 0
        @revenue = 0
        @average_check = 0
        @payments_by_method = []
        @cancelled_count = 0
        @refund_count = 0
      end
    end
  end
end
