# frozen_string_literal: true

module PrepKitchen
  class SalesPointLinkPolicy < ApplicationPolicy
    def index?
      prep_kitchen_manager? || prep_kitchen_worker?
    end

    def create?
      prep_kitchen_manager?
    end

    def destroy?
      prep_kitchen_manager?
    end
  end
end
