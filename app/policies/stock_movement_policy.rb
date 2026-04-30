# frozen_string_literal: true

# BACK-006: Pundit policy для StockMovement.
# prep_kitchen_manager может создавать/подтверждать/отменять движения.
# prep_kitchen_worker может только читать.
class StockMovementPolicy < ApplicationPolicy
  def index?
    user.has_any_role?("prep_kitchen_manager", "prep_kitchen_worker")
  end

  def show?
    user.has_any_role?("prep_kitchen_manager", "prep_kitchen_worker")
  end

  def create?
    user.has_role?("prep_kitchen_manager")
  end

  def confirm?
    user.has_role?("prep_kitchen_manager")
  end

  def cancel?
    user.has_role?("prep_kitchen_manager")
  end

  class Scope < Scope
    def resolve
      # Scope уже фильтруется по tenant_id в модели
      scope.all
    end
  end
end
