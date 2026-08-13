# frozen_string_literal: true

# Авторизация для Shop API через API ключи
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

          api_key = request.headers["X-Shop-Api-Key"] || params[:api_key]

          unless api_key.present?
            render json: { error: "Требуется авторизация" }, status: :unauthorized
            return
          end

          # Проверка API ключа (простая реализация)
          # В проде использовать зашифрованные ключи в БД
          valid_key = ENV["SHOP_API_KEY"]
          unless api_key == valid_key
            Rails.logger.warn("[Shop::Auth] Invalid API key attempt")
            render json: { error: "Неверный API ключ" }, status: :unauthorized
            nil
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
