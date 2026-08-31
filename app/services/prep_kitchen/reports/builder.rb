module PrepKitchen
  module Reports
    class Builder
      def self.call(tenant_id:, from:, to:, group_by:, user_id: nil)
        new(tenant_id: tenant_id, from: from, to: to, group_by: group_by, user_id: user_id).call
      end

      def initialize(tenant_id:, from:, to:, group_by:, user_id:)
        @tenant_id = tenant_id
        @from = from
        @to = to
        @group_by = group_by
        @user_id = user_id
      end

      def call
        base = StockMovement.where(tenant_id: @tenant_id, status: "confirmed", created_at: @from..@to)
        receipt_ids = base.where(movement_type: "receipt").pluck(:id)
        write_off_ids = base.where(movement_type: "write_off").pluck(:id)

        receipt_qty = StockMovementItem.where(movement_id: receipt_ids).sum(:qty_change)
        write_off_qty = StockMovementItem.where(movement_id: write_off_ids).sum(:qty_change)
        net_qty = receipt_qty + write_off_qty

        top_deficit = IngredientTenantStock.where(tenant_id: @tenant_id)
                        .where("qty <= min_qty AND min_qty > 0")
                        .includes(:ingredient)
                        .order(qty: :asc)
                        .limit(10)

        stop_list_manual, stop_list_auto = linked_stop_list_counts

        grouped = grouped_data(base)

        {
          receipt_qty: receipt_qty,
          write_off_qty: write_off_qty,
          net_qty: net_qty,
          stop_list_manual: stop_list_manual,
          stop_list_auto: stop_list_auto,
          top_deficit: top_deficit,
          grouped: grouped,
          linked_sales_points_count: LinkedTenantScope.linked_tenant_ids(@tenant_id).size
        }
      end

      private

      def linked_stop_list_counts
        manual = 0
        auto = 0

        LinkedTenantScope.each_linked_sales_point(prep_kitchen_tenant_id: @tenant_id, user_id: @user_id) do |tenant_id|
          manual += ProductTenantSetting.where(
            tenant_id: tenant_id, is_sold_out: true, sold_out_reason: "manual"
          ).count
          auto += ProductTenantSetting.where(
            tenant_id: tenant_id, is_sold_out: true, sold_out_reason: "stock_empty"
          ).count
        end

        [manual, auto]
      end

      def grouped_data(base_scope)
        case @group_by
        when "movement_type"
          base_scope.group(:movement_type).count
        when "ingredient"
          StockMovementItem.joins(:ingredient, :movement)
            .where(stock_movements: { id: base_scope.select(:id) })
            .group("ingredients.name")
            .sum(:qty_change)
        else
          base_scope.group("DATE(stock_movements.created_at)").count
        end
      end
    end
  end
end
