# frozen_string_literal: true

module PrepKitchen
  class BasePolicy < ApplicationPolicy
    private

    def prep_access?
      module_enabled?(:prep_kitchen) && prep_kitchen_tenant?
    end

    def prep_staff?
      prep_access? && (prep_kitchen_manager? || prep_kitchen_worker?)
    end

    def prep_manager?
      prep_access? && prep_kitchen_manager?
    end
  end
end
