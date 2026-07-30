# frozen_string_literal: true

module Payments
  # #34 SBP Autopay: GetAddAccountQRState + ChargeQr (отдельно от TbankAdapter).
  class TbankSbpAutopay
    BASE_URL = "https://securepay.tinkoff.ru/v2"

    class Error < StandardError; end

    class ChargeDeclined < Error
      attr_reader :error_code, :fatal, :bank_message, :bank_error_code

      def initialize(message, fatal: false, bank_error_code: nil)
        @error_code = "CHARGE_DECLINED"
        @fatal = fatal
        @bank_error_code = bank_error_code.to_s.presence
        @bank_message = message
        super(message)
      end

      def fatal?
        @fatal
      end
    end

    def initialize(http: nil, adapter: nil)
      @http = http
      @adapter = adapter || TbankAdapter.new
    end

    def get_add_account_qr_state(request_key:)
      body = signed_body("RequestKey" => request_key.to_s)
      response = post!("#{BASE_URL}/GetAddAccountQRState", body)
      token = response["AccountToken"].to_s.presence
      raise Error, "GetAddAccountQRState: пустой AccountToken" if token.blank?

      { account_token: token, raw: response, status: response["Status"].to_s }
    end

    def charge_qr(payment_id:, account_token:)
      body = signed_body(
        "PaymentId" => payment_id.to_s,
        "AccountToken" => account_token.to_s
      )
      response = post!("#{BASE_URL}/ChargeQr", body)

      unless response["Success"]
        raise ChargeDeclined.new(
          response["Message"].presence || "Автоплатёж СБП отклонён",
          fatal: fatal_decline?(response),
          bank_error_code: response["ErrorCode"]
        )
      end

      {
        status: response["Status"].to_s,
        payment_id: response["PaymentId"].to_s.presence || payment_id.to_s,
        raw: response
      }
    end

    private

    def signed_body(extra)
      payload = { "TerminalKey" => terminal_key }.merge(extra)
      payload["Token"] = @adapter.build_token(payload)
      payload
    end

    def post!(path, body)
      response = if @http
        @http.post(path, body)
      else
        @adapter.send(:post_json, path, body)
      end
      raise Error, "Некорректный ответ Т-Банка" unless response.is_a?(Hash)

      response
    end

    def terminal_key
      ENV.fetch("TBANK_TERMINAL_KEY") { raise Error, "TBANK_TERMINAL_KEY не задан" }
    end

    def fatal_decline?(response)
      msg = [ response["Message"], response["Details"] ].compact.join(" ").downcase
      msg.include?("счет закрыт") || msg.include?("счёт закрыт") || msg.include?("account closed")
    end
  end
end
