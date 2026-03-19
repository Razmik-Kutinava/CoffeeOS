module PrepKitchen
  module Incidents
    class Collector
      def self.call(tenant_id:)
        new(tenant_id: tenant_id).call
      end

      def initialize(tenant_id:)
        @tenant_id = tenant_id
      end

      def call
        {
          out_of_stock: IngredientTenantStock.where(tenant_id: @tenant_id).out_of_stock.includes(:ingredient).limit(100),
          low_stock: IngredientTenantStock.where(tenant_id: @tenant_id).low_stock.includes(:ingredient).limit(100),
          stale_drafts: StockMovement.where(tenant_id: @tenant_id, status: "draft").where("created_at < ?", 4.hours.ago).order(created_at: :asc).limit(100),
          stock_empty_stop_list: ProductTenantSetting.where(tenant_id: @tenant_id, is_sold_out: true, sold_out_reason: "stock_empty").order(updated_at: :desc).limit(100)
        }
      end
    end
  end
end
