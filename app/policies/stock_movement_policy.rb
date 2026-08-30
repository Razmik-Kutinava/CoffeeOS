# frozen_string_literal: true

class StockMovementPolicy < ApplicationPolicy
  def prep_access?
    module_enabled?(:prep_kitchen) && prep_kitchen_tenant?
  end

  def index?
    prep_access? && (prep_kitchen_manager? || prep_kitchen_worker?)
  end

  def show?
    prep_access? && (prep_kitchen_manager? || prep_kitchen_worker?)
  end

  def create?
    prep_access? && prep_kitchen_manager?
  end

  def confirm?
    prep_access? && prep_kitchen_manager?
  end

  def cancel?
    prep_access? && prep_kitchen_manager?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
