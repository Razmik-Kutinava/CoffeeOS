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
          ProductTenantSync.sync_product_to_all_tenants!(product: @product, user: @user)
        end

        @product
      end
    end
  end
end
