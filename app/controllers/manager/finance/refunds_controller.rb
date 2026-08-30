module Manager
  module Finance
    class RefundsController < ::Manager::BaseController
      skip_before_action :skip_authorization
      after_action :verify_authorized

      def index
        authorize Refund, :index?, policy_class: ::Finance::RefundPolicy
        scope = Refund.for_current_tenant.includes(:payment, :order)

        if shift_manager?
          shift = current_cash_shift
          return @refunds = [] unless shift

          scope = scope.joins(:order).where(orders: { cash_shift_id: shift.id })
        end

        scope = scope.order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?

        @refunds = scope.limit(300)
      end
    end
  end
end
