# frozen_string_literal: true

module PrepKitchen
  class SalesPointLink < ApplicationRecord
    self.table_name = "prep_kitchen_sales_point_links"

    belongs_to :prep_kitchen_tenant, class_name: "Tenant"
    belongs_to :sales_point_tenant, class_name: "Tenant"

    validates :sales_point_tenant_id, uniqueness: true
    validate :tenant_types
    validate :same_organization

    private

    def tenant_types
      unless prep_kitchen_tenant&.production_kitchen?
        errors.add(:prep_kitchen_tenant, "must be production_kitchen")
      end
      unless sales_point_tenant&.sales_point?
        errors.add(:sales_point_tenant, "must be sales_point")
      end
    end

    def same_organization
      return if prep_kitchen_tenant.blank? || sales_point_tenant.blank?

      kitchen_org_id = prep_kitchen_tenant.organization_id
      point_org_id = sales_point_tenant.organization_id

      if kitchen_org_id.blank?
        errors.add(:prep_kitchen_tenant, "must belong to an organization")
      elsif point_org_id.blank? || point_org_id != kitchen_org_id
        errors.add(:sales_point_tenant, "must belong to the same organization as prep kitchen")
      end
    end
  end
end
