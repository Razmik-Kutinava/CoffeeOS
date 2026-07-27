# frozen_string_literal: true

module Payments
  # Получение SBP deep link через Т-Касса `/v2/GetQr` (DataType=PAYMENT_LINK).
  # HTTP/Token — через `TbankAdapter` (не дублируем клиент).
  class TbankQrFetcher
    class Error < StandardError; end

    DATA_TYPE = "PAYMENT_LINK"

    def self.call!(payment_id:, adapter: TbankAdapter.new)
      new(payment_id: payment_id, adapter: adapter).call!
    end

    def initialize(payment_id:, adapter:)
      @payment_id = payment_id.to_s.strip
      @adapter = adapter
    end

    def call!
      raise Error, "payment_id обязателен для GetQr" if @payment_id.blank?

      payload = {
        "TerminalKey" => terminal_key,
        "PaymentId" => @payment_id,
        "DataType" => DATA_TYPE
      }
      payload["Token"] = @adapter.build_token(payload)

      response = @adapter.send(:with_circuit_breaker) do
        @adapter.send(:post_json, "#{TbankAdapter::BASE_URL}/GetQr", payload)
      end

      unless response.is_a?(Hash)
        raise Error, "Некорректный ответ Т-Банка (GetQr)"
      end
      unless response["Success"]
        raise TbankAdapter::ApiError.new(
          error_code: response["ErrorCode"],
          message: response["Message"].to_s
        )
      end

      data = response["Data"].to_s
      raise Error, "GetQr не вернул Data (PAYMENT_LINK)" if data.blank?

      { payment_url: data, data: data }
    end

    private

    def terminal_key
      ENV.fetch("TBANK_TERMINAL_KEY") { raise TbankAdapter::Error, "TBANK_TERMINAL_KEY не задан" }
    end
  end
end
