module PrepKitchen
  class InventoryController < BaseController
    def index
      @filter = sanitize_filter(params[:filter])
      @stocks = IngredientTenantStock.for_current_tenant.includes(:ingredient)

      @stocks = case @filter
                when "low" then @stocks.low_stock
                when "out" then @stocks.out_of_stock
                else @stocks
                end

      if params[:q].present?
        q = "%#{params[:q].strip}%"
        @stocks = @stocks.joins(:ingredient).where("ingredients.name ILIKE ?", q)
      end

      @stocks = @stocks.order("ingredients.name ASC").references(:ingredient).limit(500)
    end

    def update_min_qty
      return forbidden unless prep_kitchen_manager?

      stock = IngredientTenantStock.for_current_tenant.find(params[:id])
      if stock.update(min_qty: params[:min_qty])
        redirect_to prep_kitchen_inventory_path, notice: "Минимальный остаток обновлён"
      else
        redirect_to prep_kitchen_inventory_path, alert: stock.errors.full_messages.join(", ")
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to prep_kitchen_inventory_path, alert: "Остаток не найден"
    end

    private

    def sanitize_filter(value)
      allowed = %w[all low out]
      allowed.include?(value) ? value : "all"
    end

    def forbidden
      redirect_to prep_kitchen_inventory_path, alert: "Недостаточно прав"
    end
  end
end
