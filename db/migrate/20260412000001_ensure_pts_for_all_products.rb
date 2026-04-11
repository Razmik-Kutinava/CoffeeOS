class EnsurePtsForAllProducts < ActiveRecord::Migration[8.1]
  def up
    tenants = Tenant.all.to_a
    return if tenants.empty?

    Product.where(is_active: true).find_each do |product|
      fallback_price = product.base_price.presence&.to_d
      fallback_price = BigDecimal("1") if fallback_price.blank? || fallback_price <= 0

      tenants.each do |tenant|
        pts = ProductTenantSetting.find_or_initialize_by(
          tenant_id: tenant.id,
          product_id: product.id
        )
        next if pts.persisted? # уже есть — не трогаем

        pts.price        = fallback_price
        pts.is_enabled   = true
        pts.is_sold_out  = false
        pts.sold_out_reason = nil
        pts.save!
        say "PTS создан: product=#{product.name} tenant=#{tenant.slug}"
      end
    end
  end

  def down; end
end
