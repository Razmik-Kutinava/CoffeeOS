# frozen_string_literal: true

module PrepKitchen
  class RecipePolicy < BasePolicy
    def index?
      prep_manager?
    end
  end
end
