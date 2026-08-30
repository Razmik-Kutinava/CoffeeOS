module Manager
  class InventoryController < BaseController
    skip_before_action :skip_authorization
    after_action :verify_authorized
    before_action :require_general_or_franchise_manager!

    def index
      authorize IngredientTenantStock, :index?, policy_class: Manager::InventoryPolicy
      @stocks = policy_scope(IngredientTenantStock, policy_scope_class: Manager::InventoryPolicy::Scope)
        .for_current_tenant.includes(:ingredient).order("ingredient_id ASC").limit(500)
    end
  end
end
