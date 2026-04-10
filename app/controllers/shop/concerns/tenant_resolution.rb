# frozen_string_literal: true

module Shop
  module Concerns
    module TenantResolution
    extend ActiveSupport::Concern

    private

    def resolved_shop_tenant_id
      params[:tenant_id].presence ||
        request.headers["X-Shop-Tenant"].presence ||
        ENV.fetch("SHOP_DEFAULT_TENANT_ID", nil).presence ||
        single_tenant_fallback_id ||
        development_fallback_tenant_id
    end

    # Если в базе ровно одна активная точка — используем её автоматически.
    # Удобно для production без явно заданного SHOP_DEFAULT_TENANT_ID.
    def single_tenant_fallback_id
      tenants = Tenant.where(status: "active")
      return unless tenants.count == 1

      tenant = tenants.first
      Rails.logger.info("[shop] Витрина: единственная точка #{tenant.slug} (#{tenant.id})")
      tenant.id
    end

    def development_fallback_tenant_id
      return unless Rails.env.development? || Rails.env.test?

      # Сначала точка из сидов витрины / test users — иначе «первый tenant» часто без каталога.
      tenant = Tenant.find_by(slug: "test-cafe") || Tenant.order(:created_at).first
      if tenant
        Rails.logger.info("[shop] Витрина (dev): точка #{tenant.slug} (#{tenant.id})")
        tenant.id
      end
    end

    def apply_shop_tenant!(tenant)
      Current.tenant_id = tenant.id
    end
    end
  end
end
