# frozen_string_literal: true

# Shop API auth: browser CSRF+Referer vs server API key (tenant-scoped).
# Документация: docs/product/security/phase_1_rbac_closure/SHOP_API_AUTH.md
# Order ownership (Phase 1): app/controllers/concerns/shop/api/order_ownership.rb
Rails.application.config.to_prepare do
  module Shop
    module Api
      module Auth
        extend ActiveSupport::Concern

        included do
          before_action :authenticate_shop_api!, unless: -> { Rails.env.test? }
        end

        private

        def authenticate_shop_api!
          return if browser_shop_session?

          # Query/body api_key — запрещены (утечка в логи/Referer).
          if params[:api_key].present?
            render json: { error: "Требуется авторизация" }, status: :unauthorized
            return
          end

          api_key = request.headers["X-Shop-Api-Key"].to_s
          unless api_key.present?
            render json: { error: "Требуется авторизация" }, status: :unauthorized
            return
          end

          tenant_id = Current.tenant_id.presence || request.headers["X-Shop-Tenant"].presence

          begin
            Shop::ApiKeyAuthenticator.call!(raw_key: api_key, tenant_id: tenant_id)
          rescue Shop::ApiKeyAuthenticator::Unauthorized
            Rails.logger.warn("[Shop::Auth] Invalid or mismatched shop API key")
            render json: { error: "Неверный API ключ" }, status: :unauthorized
          end
        end

        def browser_shop_session?
          return false unless shop_browser_referer?

          token = request.headers["X-CSRF-Token"].presence
          return false if token.blank?

          valid_authenticity_token?(session, token)
        end

        def shop_browser_referer?
          referer = request.referer.to_s
          return false if referer.blank?

          base = request.base_url
          referer.start_with?(base) && referer.include?("/shop")
        end
      end
    end
  end
end
