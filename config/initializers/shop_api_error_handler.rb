# frozen_string_literal: true

# Глобальный обработчик ошибок для Shop API
Rails.application.config.to_prepare do
  module Shop
    module Api
      module ErrorHandler
        extend ActiveSupport::Concern

        included do
          rescue_from StandardError, with: :handle_standard_error
          rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
          rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
        end

        private

        def handle_standard_error(exception)
          Rails.logger.error("[Shop::API] #{exception.class}: #{exception.message}")
          Rails.logger.error(exception.backtrace.join("\n"))
          render json: { error: "Внутренняя ошибка сервера" }, status: :internal_server_error
        end

        def handle_not_found(exception)
          Rails.logger.warn("[Shop::API] #{exception.class}: #{exception.message}")
          render json: { error: exception.message }, status: :not_found
        end

        def handle_record_invalid(exception)
          Rails.logger.warn("[Shop::API] #{exception.class}: #{exception.message}")
          render json: { error: exception.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end
    end
  end
end
