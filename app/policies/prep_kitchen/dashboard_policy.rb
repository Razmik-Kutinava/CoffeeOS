# frozen_string_literal: true

module PrepKitchen
  class DashboardPolicy < BasePolicy
    def show?
      prep_staff?
    end
  end
end
