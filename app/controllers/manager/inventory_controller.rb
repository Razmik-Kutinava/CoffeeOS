module Manager
  class InventoryController < BaseController
    def index
      @stocks = IngredientTenantStock.for_current_tenant.includes(:ingredient).order("ingredient_id ASC").limit(500)
    end
  end
end

