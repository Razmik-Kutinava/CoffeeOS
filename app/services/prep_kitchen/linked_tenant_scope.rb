# frozen_string_literal: true

module PrepKitchen
  # G-12: итерация linked sales points с RLS GUC per tenant.
  class LinkedTenantScope
    def self.linked_tenant_ids(prep_kitchen_tenant_id)
      SalesPointRegistry.sales_points_for(prep_kitchen_tenant_id).pluck(:id)
    end

    def self.each_linked_sales_point(prep_kitchen_tenant_id:, user_id: nil)
      linked_tenant_ids(prep_kitchen_tenant_id).each do |tenant_id|
        with_tenant(tenant_id: tenant_id, user_id: user_id) { yield tenant_id }
      end
    end

    def self.flat_map(prep_kitchen_tenant_id:, user_id: nil)
      results = []
      each_linked_sales_point(prep_kitchen_tenant_id: prep_kitchen_tenant_id, user_id: user_id) do |tenant_id|
        chunk = yield tenant_id
        results.concat(Array(chunk))
      end
      results
    end

    def self.with_linked_sales_point(prep_kitchen_tenant_id:, sales_point_tenant_id:, user_id: nil)
      return unless SalesPointRegistry.serves_sales_point?(
        prep_kitchen_tenant_id: prep_kitchen_tenant_id,
        sales_point_tenant_id: sales_point_tenant_id
      )

      with_tenant(tenant_id: sales_point_tenant_id, user_id: user_id) { yield sales_point_tenant_id }
    end

    def self.with_tenant(tenant_id:, user_id: nil)
      ActiveRecord::Base.transaction do
        conn = ActiveRecord::Base.connection
        conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant_id.to_s)}")
        conn.execute("SET LOCAL app.current_user_id = #{conn.quote(user_id.to_s)}") if user_id.present?

        yield tenant_id
      end
    end
  end
end
