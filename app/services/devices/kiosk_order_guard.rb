# frozen_string_literal: true

module Devices
  # ABAC-058: kiosk-bound shop order create via X-Device-Token.
  class KioskOrderGuard
    Channel = Struct.new(:source, :device, keyword_init: true)

    def self.resolve(request:, tenant:)
      token = request.headers["X-Device-Token"].presence || request.params[:device_token].presence
      return Channel.new(source: :mobile, device: nil) if token.blank?

      auth = DeviceAuthPolicy.new(token: token, device_type: "kiosk", tenant_id: tenant.id)
      raise Shop::OrderCreator::Error, "Недействительный киоск" unless auth.authenticate?

      device = auth.device
      raise Shop::OrderCreator::Error, "Киоск не привязан к точке" unless device.tenant_id == tenant.id

      Channel.new(source: :kiosk, device: device)
    end
  end
end
