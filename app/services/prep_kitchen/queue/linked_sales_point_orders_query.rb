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
        return [] if LinkedTenantScope.linked_tenant_ids(@prep_kitchen_tenant_id).empty?

        merged = LinkedTenantScope.flat_map(prep_kitchen_tenant_id: @prep_kitchen_tenant_id, user_id: @user_id) do |tenant_id|
          Order.where(tenant_id: tenant_id)
               .where(status: @statuses)
               .where(created_at: @from..@to)
               .includes(:order_items, :tenant)
               .order(created_at: :asc)
               .limit(@limit)
               .to_a
        end
        merged.sort_by!(&:created_at)
        merged.take(@limit)
      end
    end
  end
end
