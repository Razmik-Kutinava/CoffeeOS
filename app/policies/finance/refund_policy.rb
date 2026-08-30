# frozen_string_literal: true

module Finance
  class RefundPolicy < ApplicationPolicy
    def index? = any_manager?

    class Scope < ApplicationPolicy::Scope
      def resolve
        scope.for_current_tenant
      end
    end
  end
end
