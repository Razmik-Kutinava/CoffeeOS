# frozen_string_literal: true

module Shop
  module Catalog
    module_function

    def products_scope(tenant_id)
      Product.joins(:product_tenant_settings)
        .where(product_tenant_settings: { tenant_id: tenant_id })
        .merge(ProductTenantSetting.available)
        .distinct
    end

    def stock_for_display(setting)
      return 999 if setting.stock_qty.nil?

      setting.stock_qty.to_i
    end
  end
end
