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
      @cache_version = vite_manifest_cache_version
      response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
      render "shop/pwa/service_worker", formats: :js, content_type: "application/javascript", layout: false
    end

    private

    def manifest_tenant_id
      params[:tenant_id].presence || ENV["SHOP_DEFAULT_TENANT_ID"].presence
    end

    # Версия кеша SW = первые 8 символов MD5 от Vite manifest.json.
    # Автоматически меняется при каждом деплое с новыми фронтенд-ассетами.
    # Фолбек на ENV или статическую версию если манифест не найден.
    def vite_manifest_cache_version
      manifest_path = Rails.root.join("public/vite/.vite/manifest.json")
      if manifest_path.exist?
        Digest::MD5.hexdigest(manifest_path.read)[0, 8]
      else
        ENV.fetch("SHOP_PWA_CACHE_VERSION", "b14-1")
      end
    end
  end
end
