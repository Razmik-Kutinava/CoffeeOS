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
        development_fallback_tenant_id
    end

    def development_fallback_tenant_id
      return unless Rails.env.development? || Rails.env.test?

      Tenant.order(:created_at).pick(:id).tap do |id|
        Rails.logger.info("[shop] Using first tenant as fallback: #{id}") if id
      end
    end

    def apply_shop_tenant!(tenant)
      Current.tenant_id = tenant.id
    end
    end
  end
end
