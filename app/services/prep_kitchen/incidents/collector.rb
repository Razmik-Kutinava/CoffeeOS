module PrepKitchen
  module Incidents
    class Collector
      def self.call(tenant_id:, user_id: nil)
        new(tenant_id: tenant_id, user_id: user_id).call
      end

      def initialize(tenant_id:, user_id: nil)
        @tenant_id = tenant_id
        @user_id = user_id
      end

      def call
        {
          out_of_stock: IngredientTenantStock.where(tenant_id: @tenant_id).out_of_stock.includes(:ingredient).limit(100),
          low_stock: IngredientTenantStock.where(tenant_id: @tenant_id).low_stock.includes(:ingredient).limit(100),
          stale_drafts: StockMovement.where(tenant_id: @tenant_id, status: "draft").where("created_at < ?", 4.hours.ago).order(created_at: :asc).limit(100),
          stock_empty_stop_list: linked_stock_empty_stop_list
        }
      end

      private

      def linked_stock_empty_stop_list
        items = LinkedTenantScope.flat_map(prep_kitchen_tenant_id: @tenant_id, user_id: @user_id) do |tenant_id|
          ProductTenantSetting.where(tenant_id: tenant_id, is_sold_out: true, sold_out_reason: "stock_empty")
                              .includes(:product, :tenant)
                              .order(updated_at: :desc)
                              .limit(100)
                              .to_a
        end
        items.sort_by(&:updated_at).reverse.take(100)
      end
    end
  end
end
