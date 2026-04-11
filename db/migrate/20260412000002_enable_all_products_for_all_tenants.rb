class EnableAllProductsForAllTenants < ActiveRecord::Migration[8.1]
  def up
    tenants = Tenant.all.to_a
    return say("Нет тенантов — пропускаем") if tenants.empty?

    products = Product.where(is_active: true).to_a
    return say("Нет активных товаров — пропускаем") if products.empty?

    products.each do |product|
      fallback_price = product.base_price.presence&.to_d
      fallback_price = BigDecimal("100") if fallback_price.blank? || fallback_price <= 0

      tenants.each do |tenant|
        pts = ProductTenantSetting.find_or_initialize_by(
          tenant_id: tenant.id,
          product_id: product.id
        )

        pts.price         = pts.price.presence&.to_d || fallback_price
        pts.price         = fallback_price if pts.price <= 0
        pts.is_enabled    = true
        pts.is_sold_out   = false
        pts.sold_out_reason = nil

        if pts.save
          say "OK: #{product.name} / #{tenant.slug}"
        else
          say "ERR: #{product.name} / #{tenant.slug} — #{pts.errors.full_messages.join(', ')}"
        end
      end
    end
  end

  def down; end
end
