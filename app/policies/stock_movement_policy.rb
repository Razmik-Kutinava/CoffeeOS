# frozen_string_literal: true

# BACK-006: Pundit policy для StockMovement.
# prep_kitchen_manager может создавать/подтверждать/отменять движения.
# prep_kitchen_worker может только читать.
class StockMovementPolicy < ApplicationPolicy
  def index?
    prep_kitchen_manager? || prep_kitchen_worker?
  end

  def show?
    prep_kitchen_manager? || prep_kitchen_worker?
  end

  def create?
    prep_kitchen_manager?
  end

  def confirm?
    prep_kitchen_manager?
  end

  def cancel?
    prep_kitchen_manager?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
