# frozen_string_literal: true

module Devices
  # ABAC-056/057: device token authentication (kiosk, TV).
  class DeviceAuthPolicy
    attr_reader :device

    def initialize(token:, device_type:, tenant_id: nil)
      @token = token.to_s.strip
      @device_type = device_type.to_s
      @tenant_id = tenant_id
      @device = nil
    end

    def authenticate?
      @device = TokenResolver.find_active(token: @token, device_type: @device_type)
      return false unless @device
      return false if @tenant_id.present? && @device.tenant_id.to_s != @tenant_id.to_s

      case @device_type
      when "kiosk"
        kiosk_module_enabled?(@device.tenant_id)
      else
        true
      end
    end

    private

    def kiosk_module_enabled?(tenant_id)
      flags = PolicyContext.load_module_flags(tenant_id)
      return true unless flags.key?(:kiosk)

      flags[:kiosk]
    end
  end
end
