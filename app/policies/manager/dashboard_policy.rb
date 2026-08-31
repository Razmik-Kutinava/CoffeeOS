# frozen_string_literal: true

module Manager
  # IB-D-05: manager dashboard — any_manager? (shift / GM / franchise / UK).
  class DashboardPolicy < ApplicationPolicy
    def show?
      any_manager?
    end
  end
end
