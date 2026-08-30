# frozen_string_literal: true

module Manager
  # ABAC-035: incidents dashboard (virtual aggregate, tenant-scoped).
  class IncidentPolicy < ApplicationPolicy
    def index?
      any_manager?
    end
  end
end
