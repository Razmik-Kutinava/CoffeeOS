module Manager
  class InventoryController < BaseController
    # BUG-015 FIX: Склад доступен только office_manager и franchise_manager.
    # shift_manager по матрице доступа не имеет доступа к управлению складом.
    before_action :require_office_or_franchise_manager!

    def index
      @stocks = IngredientTenantStock.for_current_tenant.includes(:ingredient).order("ingredient_id ASC").limit(500)
    end
  end
end

