# frozen_string_literal: true

module Platform
  module TenantOnboarding
    # Создаёт ProductTenantSetting для всех активных продуктов каталога УК под новую точку.
    # Вызывать внутри транзакции после SET LOCAL app.current_user_id и app.current_tenant_id.
    class CatalogBootstrap
      def self.ensure_pts_for_tenant!(tenant)
        fallback_price = BigDecimal("1")
        active_products = Product.where(is_active: true).to_a
        return if active_products.empty?

        existing_by_product_id = ProductTenantSetting
          .where(tenant_id: tenant.id, product_id: active_products.map(&:id))
          .index_by(&:product_id)

        active_products.each do |product|
          next if existing_by_product_id[product.id]

          bp = product.base_price.presence&.to_d
          bp = fallback_price if bp.blank? || bp <= 0

          ProductTenantSetting.create!(
            tenant_id: tenant.id,
            product_id: product.id,
            price: bp,
            is_enabled: true,
            is_sold_out: false,
            sold_out_reason: nil
          )
        end
      end
    end
  end
end
