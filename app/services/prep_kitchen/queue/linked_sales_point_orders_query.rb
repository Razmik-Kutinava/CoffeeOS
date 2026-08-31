# frozen_string_literal: true

module PrepKitchen
  module Queue
    # G-12: заказы linked sales points для очереди цеха (RLS per linked tenant GUC).
    class LinkedSalesPointOrdersQuery
      def self.call(prep_kitchen_tenant_id:, from:, to:, statuses:, user_id: nil, limit: 200)
        new(
          prep_kitchen_tenant_id: prep_kitchen_tenant_id,
          from: from,
          to: to,
          statuses: statuses,
          user_id: user_id,
          limit: limit
        ).call
      end

      def initialize(prep_kitchen_tenant_id:, from:, to:, statuses:, user_id:, limit:)
        @prep_kitchen_tenant_id = prep_kitchen_tenant_id
        @from = from
        @to = to
        @statuses = Array(statuses)
        @user_id = user_id
        @limit = limit
      end

      def call
        tenant_ids = SalesPointRegistry.sales_points_for(@prep_kitchen_tenant_id).pluck(:id)
        return [] if tenant_ids.empty?

        merged = tenant_ids.flat_map { |tenant_id| fetch_for_tenant(tenant_id) }
        merged.sort_by!(&:created_at)
        merged.take(@limit)
      end

      private

      def fetch_for_tenant(tenant_id)
        ActiveRecord::Base.transaction do
          conn = ActiveRecord::Base.connection
          conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant_id.to_s)}")
          conn.execute("SET LOCAL app.current_user_id = #{conn.quote(@user_id.to_s)}") if @user_id.present?

          Order.where(tenant_id: tenant_id)
               .where(status: @statuses)
               .where(created_at: @from..@to)
               .includes(:order_items, :tenant)
               .order(created_at: :asc)
               .limit(@limit)
               .to_a
        end
      end
    end
  end
end
