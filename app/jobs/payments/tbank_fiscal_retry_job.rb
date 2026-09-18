# frozen_string_literal: true

module Payments
  # One deferred retry for TbankFiscalNotificationHandler when payment was not found yet.
  class TbankFiscalRetryJob < ApplicationJob
    queue_as :default

    def perform(payload, attempt = 1)
      TbankFiscalNotificationHandler.new(
        payload: payload,
        retry_attempt: attempt.to_i
      ).call!
    end
  end
end
