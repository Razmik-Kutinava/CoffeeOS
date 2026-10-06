# frozen_string_literal: true

module Platform
  module TenantsHelper
    def uk_tenant_type_label(tenant)
      tenant.production_kitchen? ? "Цех" : "Точка продаж"
    end

    def uk_tenant_status_label(tenant)
      tenant.status == "active" ? "активна" : "неактивна (#{tenant.status})"
    end
  end
end
