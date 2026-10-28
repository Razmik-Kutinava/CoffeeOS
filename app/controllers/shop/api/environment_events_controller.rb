# frozen_string_literal: true

module Shop
  module Api
    # TASK_112: публичный приём снимка окружения витрины (sendBeacon / fetch keepalive).
    # Авторизация гостя не нужна; точка — из with_shop_tenant!, не из тела.
    # sendBeacon может прислать text/plain — тело разбираем сами.
    # sendBeacon не умеет X-CSRF-Token / X-Shop-Api-Key → без skip prod отвечает 401.
    # Риск публичного POST: только enum-флаги, точка с сервера, Rack::Attack 30/мин/IP.
    class EnvironmentEventsController < Shop::Api::BaseController
      MAX_BODY_BYTES = ShopEnvironmentEventsBodyLimit::MAX_BODY_BYTES

      skip_before_action :authenticate_shop_api!, only: :create

      # Битый JSON с типом application/json падает ещё в with_shop_tenant! (params) — иначе 500.
      rescue_from ActionDispatch::Http::Parameters::ParseError do
        render json: { error: "invalid json" }, status: :unprocessable_entity
      end

      def create
        payload = parse_payload
        return head 413 if payload == :too_large
        return render json: { error: "invalid json" }, status: :unprocessable_entity if payload.nil?

        result = Shop::EnvironmentEventRecorder.call(point_id: @shop_tenant.id, payload: payload)
        return head :no_content if result.ok?

        render json: { error: result.error.to_s }, status: :unprocessable_entity
      end

      private

      def parse_payload
        raw = request.raw_post.to_s
        return :too_large if raw.bytesize > MAX_BODY_BYTES
        return {} if raw.strip.empty?

        data = JSON.parse(raw)
        data.is_a?(Hash) ? data : nil
      rescue JSON::ParserError
        nil
      end
    end
  end
end
