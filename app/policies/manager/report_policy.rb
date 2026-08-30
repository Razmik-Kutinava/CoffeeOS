# frozen_string_literal: true

module Manager
  # ABAC-042: reports read access for managers (shift_manager = current shift only in controller scope).
  class ReportPolicy < ApplicationPolicy
    def index?
      any_manager?
    end
  end
end
