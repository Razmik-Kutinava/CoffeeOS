# frozen_string_literal: true

module PrepKitchen
  # G-12: связь заготовочного цеха с точками продаж (1 kitchen → N sales points).
  class SalesPointRegistry
    class Error < StandardError; end

    def self.link!(prep_kitchen_tenant:, sales_point_tenant:)
      new(prep_kitchen_tenant).link!(sales_point_tenant)
    end

    def self.sales_points_for(prep_kitchen_tenant_id)
      ids = SalesPointLink.where(prep_kitchen_tenant_id: prep_kitchen_tenant_id).pluck(:sales_point_tenant_id)
      Tenant.where(id: ids).order(:name)
    end

    def self.prep_kitchen_for(sales_point_tenant_id)
      link = SalesPointLink.find_by(sales_point_tenant_id: sales_point_tenant_id)
      link&.prep_kitchen_tenant
    end

    def self.serves_sales_point?(prep_kitchen_tenant_id:, sales_point_tenant_id:)
      SalesPointLink.exists?(
        prep_kitchen_tenant_id: prep_kitchen_tenant_id,
        sales_point_tenant_id: sales_point_tenant_id
      )
    end

    def initialize(prep_kitchen_tenant)
      @prep_kitchen_tenant = prep_kitchen_tenant
    end

    def link!(sales_point_tenant)
      unless @prep_kitchen_tenant.production_kitchen?
        raise Error, "prep kitchen tenant must be production_kitchen"
      end
      unless sales_point_tenant.sales_point?
        raise Error, "sales point tenant must be sales_point"
      end

      SalesPointLink.find_or_create_by!(
        prep_kitchen_tenant: @prep_kitchen_tenant,
        sales_point_tenant: sales_point_tenant
      )
    end
  end
end
