# frozen_string_literal: true

module Finance
  class PaymentPolicy < ApplicationPolicy
    def index? = any_manager?

    class Scope < ApplicationPolicy::Scope
      def resolve
        base = scope.for_current_tenant
        return base.none if shift_manager? && context&.shift.blank?
        return base unless shift_manager? && context&.shift

        base.joins(:order).where(orders: { cash_shift_id: context.shift.id })
      end
    end
  end
end
