module PrepKitchen
  class DashboardController < BaseController
    def show
      stocks = IngredientTenantStock.for_current_tenant
      @low_stock_count = stocks.low_stock.count
      @out_of_stock_count = stocks.out_of_stock.count
      @draft_movements_count = StockMovement.for_current_tenant.draft.count
      @auto_stop_list_count = linked_auto_stop_list_count
      @today_movements_count = StockMovement.for_current_tenant.where(created_at: Time.zone.today.all_day).count
      @critical_ingredients = stocks.low_stock.includes(:ingredient).order(qty: :asc).limit(10)
      @recent_movements = StockMovement.for_current_tenant.includes(:created_by).recent.limit(10)
      @linked_sales_points = PrepKitchen::SalesPointRegistry.sales_points_for(Current.tenant_id)
    end

    private

    def linked_auto_stop_list_count
      count = 0
      PrepKitchen::LinkedTenantScope.each_linked_sales_point(
        prep_kitchen_tenant_id: Current.tenant_id,
        user_id: Current.user_id
      ) do |tenant_id|
        count += ProductTenantSetting.where(
          tenant_id: tenant_id, is_sold_out: true, sold_out_reason: "stock_empty"
        ).count
      end
      count
    end
  end
end
