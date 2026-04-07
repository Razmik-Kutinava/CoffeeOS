# frozen_string_literal: true

module Shop
  module Catalog
    module_function

    def products_scope(tenant_id)
      Product.active.joins(:product_tenant_settings)
        .where(product_tenant_settings: { tenant_id: tenant_id })
        .merge(ProductTenantSetting.available)
        .distinct
    end

    def stock_for_display(setting)
      return 999 if setting.stock_qty.nil?

      setting.stock_qty.to_i
    end

    # Товары, доступные на витрине для точки (есть PTS и включено / не sold_out).
    def enabled_products_count(tenant_id)
      products_scope(tenant_id).count
    end
  end
end
