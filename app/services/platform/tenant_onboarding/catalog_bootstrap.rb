# frozen_string_literal: true

module Platform
  module TenantOnboarding
    # Создаёт ProductTenantSetting для всех активных продуктов каталога УК под новую точку.
    # Вызывать внутри транзакции после SET LOCAL app.current_user_id и app.current_tenant_id.
    class CatalogBootstrap
      def self.ensure_pts_for_tenant!(tenant)
        fallback_price = BigDecimal("1")

        Product.where(is_active: true).find_each do |product|
          bp = product.base_price.presence&.to_d
          bp = fallback_price if bp.blank? || bp <= 0

          pts = ProductTenantSetting.find_or_initialize_by(
            tenant_id: tenant.id,
            product_id: product.id
          )
          next if pts.persisted?

          pts.assign_attributes(
            price: product.base_price.presence&.to_d || bp,
            is_enabled: true,
            is_sold_out: false,
            sold_out_reason: nil
          )
          pts.price = bp if pts.price.blank? || pts.price <= 0
          pts.save!
        end
      end
    end
  end
end
