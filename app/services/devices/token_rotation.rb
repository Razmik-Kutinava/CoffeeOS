# frozen_string_literal: true

module Devices
  # Ручная ротация device_token (manager UI). Старый token перестаёт работать сразу.
  class TokenRotation
    class Error < StandardError; end

    def self.call!(device:)
      new(device: device).call!
    end

    def initialize(device:)
      @device = device
    end

    def call!
      raise Error, "Устройство неактивно" unless @device.is_active?

      new_token = SecureRandom.hex(24)
      @device.update!(
        device_token: new_token,
        is_active: true
      )
      new_token
    end
  end
end
