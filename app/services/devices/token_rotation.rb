# frozen_string_literal: true

module Devices
  # Ручная ротация device_token (manager UI). Старый token перестаёт работать сразу.
  # Также реактивирует отозванное устройство (is_active=true).
  class TokenRotation
    def self.call!(device:)
      new(device: device).call!
    end

    def initialize(device:)
      @device = device
    end

    def call!
      TokenCredentials.assign_new!(device: @device)
    end
  end
end
