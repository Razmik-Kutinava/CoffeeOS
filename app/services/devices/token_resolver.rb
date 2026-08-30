# frozen_string_literal: true

module Devices
  # IB Phase 5b: единая точка lookup device по глобально уникальному device_token.
  # До SET LOCAL tenant GUC RLS не знает tenant — row_security off только на этот SELECT.
  # device_token unique index (schema) — один токен = одна запись.
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

      device = nil
      ActiveRecord::Base.connection.transaction do
        ActiveRecord::Base.connection.execute("SET LOCAL row_security = off")
        device = Device.unscoped.find_by(
          device_token: @token,
          device_type: @device_type,
          is_active: true
        )
      end
      device if device&.token_valid?
    end
  end
end
