# frozen_string_literal: true

module Devices
  # IB-P-02: ежедневная проверка TTL device_token (деактивация + алерты).
  class RotateExpiringTokensJob < ApplicationJob
    queue_as :default

    def perform
      result = ExpiringTokensProcessor.call
      return if result.skipped_ttl

      Rails.logger.info(
        "[RotateExpiringTokensJob] deactivated=#{result.deactivated} warned=#{result.warned}"
      )
    end
  end
end
