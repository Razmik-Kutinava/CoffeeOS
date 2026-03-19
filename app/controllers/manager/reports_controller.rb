module Manager
  class ReportsController < BaseController
    def index
      from = params[:from].present? ? Time.zone.parse(params[:from]) : 7.days.ago.beginning_of_day
      to = params[:to].present? ? Time.zone.parse(params[:to]) : Time.zone.now

      orders = Order.for_current_tenant.where(created_at: from..to)
      payments = Payment.for_current_tenant.where(created_at: from..to)
      refunds = Refund.for_current_tenant.where(created_at: from..to)

      if shift_manager?
        shift = current_cash_shift
        unless shift
          @orders_count = 0
          @revenue = 0
          @refunds_sum = 0
          @cancelled_count = 0
          @from = from
          @to = to
          return
        end

        orders = orders.where(cash_shift_id: shift.id)
        payments = Payment.for_current_tenant.joins(:order)
                                          .where(created_at: from..to)
                                          .where(orders: { cash_shift_id: shift.id })
        refunds = Refund.for_current_tenant.joins(:order)
                                          .where(created_at: from..to)
                                          .where(orders: { cash_shift_id: shift.id })
      end

      @from = from
      @to = to
      @orders_count = orders.count
      @revenue = payments.where(status: "succeeded").sum(:amount)
      @refunds_sum = refunds.where(status: "succeeded").sum(:amount)
      @cancelled_count = orders.where(status: "cancelled").count
    end
  end
end

