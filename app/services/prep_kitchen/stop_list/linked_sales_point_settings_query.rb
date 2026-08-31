# frozen_string_literal: true

module PrepKitchen
  module StopList
    # G-12: ProductTenantSetting стоп-листа по linked sales points.
    class LinkedSalesPointSettingsQuery
      def self.call(prep_kitchen_tenant_id:, reason: "all", q: nil, user_id: nil, limit: 300)
        new(
          prep_kitchen_tenant_id: prep_kitchen_tenant_id,
          reason: reason,
          q: q,
          user_id: user_id,
          limit: limit
        ).call
      end

      def initialize(prep_kitchen_tenant_id:, reason:, q:, user_id:, limit:)
        @prep_kitchen_tenant_id = prep_kitchen_tenant_id
        @reason = reason
        @q = q
        @user_id = user_id
        @limit = limit
      end

      def call
        items = LinkedTenantScope.flat_map(prep_kitchen_tenant_id: @prep_kitchen_tenant_id, user_id: @user_id) do |tenant_id|
          scope_for(tenant_id).to_a
        end

        items.sort_by(&:updated_at).reverse.take(@limit)
      end

      private

      def scope_for(tenant_id)
        scope = ProductTenantSetting.where(tenant_id: tenant_id, is_sold_out: true)
                                    .includes(:product, :tenant)
        scope = scope.where(sold_out_reason: @reason) if @reason != "all"
        if @q.present?
          query = "%#{@q.strip}%"
          scope = scope.joins(:product).where("products.name ILIKE ?", query)
        end
        scope.order(updated_at: :desc).limit(@limit)
      end
    end
  end
end
