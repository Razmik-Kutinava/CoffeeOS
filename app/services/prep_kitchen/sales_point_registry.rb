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

    def self.unlink!(prep_kitchen_tenant:, sales_point_tenant_id:)
      SalesPointLink.where(
        prep_kitchen_tenant_id: prep_kitchen_tenant.id,
        sales_point_tenant_id: sales_point_tenant_id
      ).delete_all
    end

    def self.candidate_sales_points_for(prep_kitchen_tenant)
      org_id = prep_kitchen_tenant.organization_id
      return Tenant.none if org_id.blank?

      linked_ids = SalesPointLink.select(:sales_point_tenant_id)
      Tenant.where(organization_id: org_id, type: "sales_point", status: "active")
            .where.not(id: linked_ids)
            .order(:name)
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

      validate_same_organization!(sales_point_tenant)

      SalesPointLink.find_or_create_by!(
        prep_kitchen_tenant: @prep_kitchen_tenant,
        sales_point_tenant: sales_point_tenant
      )
    end

    def validate_same_organization!(sales_point_tenant)
      kitchen_org_id = @prep_kitchen_tenant.organization_id
      point_org_id = sales_point_tenant.organization_id

      if kitchen_org_id.blank?
        raise Error, "prep kitchen must belong to an organization"
      end
      if point_org_id.blank? || point_org_id != kitchen_org_id
        raise Error, "sales point must belong to the same organization as prep kitchen"
      end
    end
  end
end
