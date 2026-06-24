# frozen_string_literal: true

module Payments
  # Нормализованный ответ Init / FinishAuthorize / Charge / GetState (B1.12-R1).
  class TbankPaymentResult
    attr_reader :raw

    def initialize(raw)
      @raw = raw.is_a?(Hash) ? raw.stringify_keys : {}
    end

    def success?
      @raw["Success"] == true
    end

    def error_code
      @raw["ErrorCode"].to_s
    end

    def message
      @raw["Message"].to_s
    end

    def status
      @raw["Status"].to_s
    end

    def payment_id
      @raw["PaymentId"].to_s.presence
    end

    def three_ds?
      status.upcase == "3DS_CHECKING"
    end

    def confirmed?
      status.upcase == "CONFIRMED"
    end

    def terminal_failure?
      !success? || %w[REJECTED CANCELED].include?(status.upcase)
    end

    def three_ds_payload
      return nil unless three_ds?

      {
        acs_url: @raw["ACSUrl"],
        pa_req: @raw["PaReq"],
        md: @raw["MD"]
      }
    end

    def as_api_json
      {
        tbank_status: status.presence,
        error_code: error_code,
        message: message.presence,
        payment_id: payment_id,
        three_ds: three_ds_payload
      }.compact
    end
  end
end
