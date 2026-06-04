# frozen_string_literal: true

module Platform
  module TenantOnboarding
    # Создаёт ProductTenantSetting для всех активных продуктов каталога УК под новую точку.
    # Вызывать внутри транзакции после SET LOCAL app.current_user_id и app.current_tenant_id.
    class CatalogBootstrap
      def self.ensure_pts_for_tenant!(tenant, actor_user_id: nil)
        uid = actor_user_id.presence || Platform::Menu::ProductTenantSync.fallback_uk_user&.id
        return if uid.blank?

        Product.where(is_active: true).find_each do |product|
          Platform::Menu::ProductTenantSync.upsert_pts!(
            product: product,
            tenant_id: tenant.id,
            user_id: uid,
            fallback: Platform::Menu::ProductTenantSync.price_fallback(product),
            enabled: true
          )
        end
        Platform::Menu::ProductTenantSync.bust_shop_catalog_cache!
      ensure
        Current.tenant_id = nil
      end
    end
  end
end
