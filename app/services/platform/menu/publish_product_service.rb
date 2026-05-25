# frozen_string_literal: true

module Platform
  module Menu
    # Сохранение товара в глобальном каталоге + ProductTenantSetting на все точки (RLS).
    class PublishProductService
      def initialize(product:, user:)
        @product = product
        @user = user
      end

      def call!
        ActiveRecord::Base.transaction do
          @product.save!
          sync_tenant_settings!
        end

        @product
      end

      private

      def sync_tenant_settings!
        uid = @user.id
        fallback = @product.base_price.presence&.to_d
        fallback = BigDecimal("1") if fallback.blank? || fallback <= 0

        Tenant.select(:id).find_each do |tenant|
          ActiveRecord::Base.transaction do
            conn = ActiveRecord::Base.connection
            conn.execute("SET LOCAL app.current_user_id = #{conn.quote(uid.to_s)}")
            conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant.id.to_s)}")

            Current.tenant_id = tenant.id

            pts = ProductTenantSetting.find_or_initialize_by(tenant_id: tenant.id, product_id: @product.id)
            pts.price = @product.base_price.presence&.to_d || pts.price || fallback
            pts.price = fallback if pts.price.blank? || pts.price <= 0
            pts.is_enabled = true
            pts.is_sold_out = false
            pts.sold_out_reason = nil
            pts.save!
          end
        end
      ensure
        Current.tenant_id = nil
      end
    end
  end
end
