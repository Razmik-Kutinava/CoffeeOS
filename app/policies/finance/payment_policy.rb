# frozen_string_literal: true

module Finance
  class PaymentPolicy < ApplicationPolicy
    def index? = any_manager?

    class Scope < ApplicationPolicy::Scope
      def resolve
        scope.for_current_tenant
      end
    end
  end
end
