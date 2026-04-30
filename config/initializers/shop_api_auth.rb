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
            return
          end
        end
      end
    end
  end
end
