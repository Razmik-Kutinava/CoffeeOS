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

      if tenants.count == 1
        tenant = tenants.first
        Rails.logger.info("[shop] Витрина: единственная точка #{tenant.slug} (#{tenant.id})")
        return tenant.id
      end

      # Несколько тенантов — берём по ORG_SLUG (задаётся в setup:production)
      org_slug = ENV["ORG_SLUG"].presence
      if org_slug
        tenant = tenants.joins(:organization)
                        .where(organizations: { slug: org_slug })
                        .first
        if tenant
          Rails.logger.info("[shop] Витрина: тенант по ORG_SLUG=#{org_slug} → #{tenant.slug} (#{tenant.id})")
          return tenant.id
        end
      end

      # Последний fallback — первый активный тенант у которого есть товары
      tenant = tenants.joins(:product_tenant_settings)
                      .where(product_tenant_settings: { is_enabled: true })
                      .order(:created_at)
                      .first
      tenant ||= tenants.order(:created_at).first
      if tenant
        Rails.logger.info("[shop] Витрина: fallback-тенант #{tenant.slug} (#{tenant.id})")
        return tenant.id
      end

      nil
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
      conn = ActiveRecord::Base.connection
      conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant.id.to_s)}")
    end
    end
  end
end
