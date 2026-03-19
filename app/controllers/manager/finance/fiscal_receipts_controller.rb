module Manager
  module Finance
    class FiscalReceiptsController < ::Manager::BaseController
      def index
        scope = FiscalReceipt.for_current_tenant

        if shift_manager?
          shift = current_cash_shift
          return @receipts = [] unless shift

          scope = scope.joins(:order).where(orders: { cash_shift_id: shift.id })
        end

        scope = scope.order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(type: params[:type]) if params[:type].present?

        @receipts = scope.limit(300)
      end
    end
  end
end

