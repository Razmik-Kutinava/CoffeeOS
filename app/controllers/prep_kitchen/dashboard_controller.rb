module PrepKitchen
  class DashboardController < BaseController
    def show
      stocks = IngredientTenantStock.for_current_tenant
      @low_stock_count = stocks.low_stock.count
      @out_of_stock_count = stocks.out_of_stock.count
      @draft_movements_count = StockMovement.for_current_tenant.draft.count
      @auto_stop_list_count = ProductTenantSetting.where(tenant_id: Current.tenant_id, is_sold_out: true, sold_out_reason: "stock_empty").count
      @today_movements_count = StockMovement.for_current_tenant.where(created_at: Time.zone.today.all_day).count
      @critical_ingredients = stocks.low_stock.includes(:ingredient).order(qty: :asc).limit(10)
      @recent_movements = StockMovement.for_current_tenant.includes(:created_by).recent.limit(10)
    end
  end
end
