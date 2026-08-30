# frozen_string_literal: true

# BACK-006: Pundit policy для IngredientTenantStock.
# prep_kitchen_manager может обновлять минимальный остаток.
# prep_kitchen_worker может только читать.
class IngredientTenantStockPolicy < ApplicationPolicy
  def index?
    prep_kitchen_manager? || prep_kitchen_worker?
  end

  def show?
    prep_kitchen_manager? || prep_kitchen_worker?
  end

  def update_min_qty?
    prep_kitchen_manager?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
