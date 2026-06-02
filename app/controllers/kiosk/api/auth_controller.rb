# frozen_string_literal: true

module Kiosk
  module Api
    # Планшет/Flutter киоск: device_token → tenant для дальнейших /shop/api/* с X-Shop-Tenant.
    class AuthController < ActionController::API
      def create
        token = device_token_from_request
        return render json: { error: "missing device token" }, status: :unauthorized if token.blank?

        device = find_active_kiosk(token)
        return render json: { error: "invalid or inactive device token" }, status: :unauthorized unless device

        device.update_columns(last_seen_at: Time.current, updated_at: Time.current)

        tenant = device.tenant
        settings = with_kiosk_tenant_guc!(tenant.id) { kiosk_settings_json(device) }
        render json: {
          tenant_id: tenant.id,
          tenant_name: tenant.name,
          tenant_slug: tenant.slug,
          device_id: device.id,
          device_name: device.name,
          kiosk_settings: settings
        }
      end

      private

      def device_token_from_request
        request.headers["X-Device-Token"].presence || params[:device_token].presence
      end

      def find_active_kiosk(token)
        device = nil
        ActiveRecord::Base.connection.transaction do
          # RLS: devices привязаны к tenant; lookup по token — до SET LOCAL tenant.
          ActiveRecord::Base.connection.execute("SET LOCAL row_security = off")
          device = Device.unscoped.find_by(
            device_token: token,
            device_type: "kiosk",
            is_active: true
          )
        end
        device if device&.token_valid?
      end

      # После lookup device с row_security off — KioskSetting только с tenant GUC (RLS).
      def with_kiosk_tenant_guc!(tenant_id)
        result = nil
        ActiveRecord::Base.transaction do
          conn = ActiveRecord::Base.connection
          conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant_id.to_s)}")
          result = yield
        end
        result
      end

      def kiosk_settings_json(device)
        setting = KioskSetting.active.find_by(device_id: device.id, tenant_id: device.tenant_id)
        return default_kiosk_settings if setting.nil?

        {
          allow_card: setting.allow_card,
          allow_cash: setting.allow_cash,
          idle_timeout_seconds: setting.idle_timeout_seconds,
          welcome_text: setting.welcome_text,
          display_settings: setting.display_settings || {}
        }
      end

      def default_kiosk_settings
        {
          allow_card: true,
          allow_cash: true,
          idle_timeout_seconds: 300,
          welcome_text: "Добро пожаловать",
          display_settings: {}
        }
      end
    end
  end
end
