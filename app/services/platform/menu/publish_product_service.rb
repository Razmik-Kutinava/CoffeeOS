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
        ActiveRecord::Base.transaction { @product.save! }
        # Sync вне транзакции save: иначе на prod nested TX иногда не фиксирует PTS до commit.
        ProductTenantSync.sync_product_to_all_tenants!(product: @product, user: @user)

        @product
      end
    end
  end
end
