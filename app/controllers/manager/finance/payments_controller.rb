module Manager
  module Finance
    class PaymentsController < ::Manager::BaseController
      skip_before_action :skip_authorization
      after_action :verify_authorized

      def index
        authorize Payment, :index?, policy_class: ::Finance::PaymentPolicy
        scope = policy_scope(Payment, policy_scope_class: ::Finance::PaymentPolicy::Scope)
        scope = scope.includes(:order)

        scope = scope.order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(method: params[:method]) if params[:method].present?

        @payments = scope.limit(300)
      end
    end
  end
end
