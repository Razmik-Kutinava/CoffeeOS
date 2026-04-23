module Manager
  module Finance
    class PaymentsController < ::Manager::BaseController
      def index
        scope = Payment.for_current_tenant.includes(:order)

        if shift_manager?
          shift = current_cash_shift
          return @payments = [] unless shift

          scope = scope.joins(:order).where(orders: { cash_shift_id: shift.id })
        end

        scope = scope.order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(method: params[:method]) if params[:method].present?

        @payments = scope.limit(300)
      end
    end
  end
end

