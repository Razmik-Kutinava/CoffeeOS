# frozen_string_literal: true

module Platform
  # Списки УК (дашборд, точки, организации): без inactive-мусора; в single-point — только Point A.
  class UkCatalogScope
    def self.tenants
      base = Tenant.includes(:organization).order(:name).limit(500)

      if SinglePointMode.enabled?
        point_a = SinglePointMode.point_a
        return Tenant.none unless point_a

        base.where(id: point_a.id)
      else
        base.where(status: "active", type: "sales_point")
      end
    end

    def self.organizations
      base = Organization.order(:name).limit(200)

      if SinglePointMode.enabled?
        point_a = SinglePointMode.point_a
        org_id = point_a&.organization_id
        return Organization.none if org_id.blank?

        base.where(id: org_id)
      else
        base.joins(:tenants).where(tenants: { status: "active", type: "sales_point" }).distinct
      end
    end
  end
end
