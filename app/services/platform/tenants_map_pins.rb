# frozen_string_literal: true

module Platform
  # B1.14-3d: маркеры для карты списка точек УК (только sales_point с координатами).
  module TenantsMapPins
    module_function

    def build(tenants, url_helpers:)
      tenants.filter_map do |tenant|
        next unless tenant.sales_point?
        next unless Shop::TenantGeo.coordinates?(tenant)

        {
          id: tenant.id.to_s,
          name: tenant.name,
          address: Shop::TenantAddress.display(city: tenant.city, address: tenant.address),
          lat: tenant.latitude.to_f,
          lng: tenant.longitude.to_f,
          card_url: url_helpers.platform_tenant_path(tenant, only_path: true)
        }
      end
    end
  end
end
