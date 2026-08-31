# frozen_string_literal: true

module PrepKitchen
  class IncidentPolicy < BasePolicy
    def index?
      prep_manager?
    end
  end
end
