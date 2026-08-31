# frozen_string_literal: true

module PrepKitchen
  class StopListPolicy < BasePolicy
    def index?
      prep_staff?
    end

    def update?
      prep_manager?
    end
  end
end
