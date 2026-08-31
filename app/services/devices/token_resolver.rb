# frozen_string_literal: true

module Devices
  # IB Phase 5b/6: lookup device по глобально уникальному device_token.
  # RLS: политика rls_devices_token_lookup + GUC app.device_token_lookup (без row_security off).
  class TokenResolver
    def self.find_active(token:, device_type:)
      new(token: token, device_type: device_type).find_active
    end

    def initialize(token:, device_type:)
      @token = token.to_s.strip
      @device_type = device_type.to_s
    end

    def find_active
      return nil if @token.blank? || @device_type.blank?

      device = Rls::GucContext.with_device_token_lookup do
        Device.find_by(
          device_token: @token,
          device_type: @device_type,
          is_active: true
        )
      end
      device if device&.token_valid?
    end
  end
end
