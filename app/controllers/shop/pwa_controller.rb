# frozen_string_literal: true

module Shop
  class PwaController < ApplicationController
    skip_forgery_protection
    layout false

    def manifest
      @start_tenant_id = manifest_tenant_id
      render "shop/pwa/manifest", formats: :json, content_type: "application/manifest+json", layout: false
    end

    def service_worker
      @cache_version = ENV.fetch("SHOP_PWA_CACHE_VERSION", "b14-1")
      render "shop/pwa/service_worker", formats: :js, content_type: "application/javascript", layout: false
    end

    private

    def manifest_tenant_id
      params[:tenant_id].presence || ENV["SHOP_DEFAULT_TENANT_ID"].presence
    end
  end
end
