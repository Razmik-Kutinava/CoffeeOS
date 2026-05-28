# frozen_string_literal: true

module Payments
  # Адаптер интернет-эквайринга Т-Банк (API v2).
  # Docs: https://www.tbank.ru/kassa/dev/payments/
  #
  # ENV:
  #   TBANK_TERMINAL_KEY  — TerminalKey (тест: 1719235292292DEMO, прод: 1719235292309)
  #   TBANK_PASSWORD      — Password терминала
  #   TBANK_RETURN_URL    — базовый URL приложения для SuccessURL/FailURL
  class TbankAdapter
    class Error < StandardError; end
    class ApiError < Error
      attr_reader :error_code, :message
      def initialize(error_code:, message:)
        @error_code = error_code
        @message = message
        super("Т-Банк API error #{error_code}: #{message}")
      end
    end

    BASE_URL = "https://securepay.tinkoff.ru/v2"

    # Circuit Breaker — Redis ключи
    CB_FAILURES_KEY  = "tbank:cb:failures"
    CB_OPEN_KEY      = "tbank:cb:open"
    CB_THRESHOLD     = 5   # ошибок подряд перед открытием
    CB_OPEN_TTL      = 60  # секунд в открытом состоянии

    # Статусы Т-Банка → наши статусы Payment
    TBANK_STATUS_MAP = {
      "CONFIRMED"        => "succeeded",
      "AUTHORIZED"       => "processing",
      "REJECTED"         => "failed",
      "REVERSED"         => "failed",
      "CANCELED"         => "failed",
      "REFUNDED"         => "refunded",
      "PARTIAL_REFUNDED" => "partially_refunded"
    }.freeze

    # Инициализирует платёж в Т-Банке.
    # Возвращает { payment_url:, provider_payment_id: }
    def init_payment(order:, return_base_url:, notification_url:)
      amount_kopecks = (order.final_amount * 100).to_i

      payload = {
        "TerminalKey"    => terminal_key,
        "Amount"         => amount_kopecks,
        "OrderId"        => order.id.to_s,
        "Description"    => "Заказ ##{order.id}",
        "SuccessURL"     => "#{return_base_url}/payment/success?order_id=#{order.id}",
        "FailURL"        => "#{return_base_url}/payment/fail?order_id=#{order.id}",
        "NotificationURL" => notification_url
      }
      payload["Token"] = build_token(payload)

      response = post_json_with_circuit_breaker("#{BASE_URL}/Init", payload)
      raise ApiError.new(error_code: response["ErrorCode"], message: response["Message"].to_s) unless response["Success"]

      {
        payment_url: response["PaymentURL"],
        provider_payment_id: response["PaymentId"].to_s
      }
    end

    # Верифицирует webhook от Т-Банка.
    # Принимает params (Hash со строковыми ключами).
    # Возвращает true/false.
    def self.verify_notification(params)
      received_token = params["Token"].to_s
      return false if received_token.blank?

      expected = new.build_token(params.except("Token"))
      ActiveSupport::SecurityUtils.secure_compare(expected, received_token)
    end

    # Переводит статус Т-Банка в наш статус Payment.
    def self.map_status(tbank_status)
      TBANK_STATUS_MAP[tbank_status.to_s.upcase]
    end

    # Публичный метод для использования в верификации (в т.ч. из self-методов)
    def build_token(params)
      values = params
        .merge("Password" => password)
        .reject { |k, _| k.to_s == "Token" }
        .sort_by { |k, _| k.to_s }
        .map { |_, v| v.to_s }
        .join
      Digest::SHA256.hexdigest(values)
    end

    private

    def post_json_with_circuit_breaker(url, payload)
      if Rails.cache.exist?(CB_OPEN_KEY)
        raise Error, "Т-Банк временно недоступен (circuit open). Попробуйте позже."
      end

      result = post_json(url, payload)
      Rails.cache.delete(CB_FAILURES_KEY)
      result
    rescue Error, Net::OpenTimeout, Net::ReadTimeout => e
      failures = Rails.cache.increment(CB_FAILURES_KEY, 1, expires_in: 5.minutes) || 1
      if failures >= CB_THRESHOLD
        Rails.cache.write(CB_OPEN_KEY, true, expires_in: CB_OPEN_TTL)
        Rails.logger.error("[TbankAdapter] Circuit opened after #{failures} failures")
      end
      raise
    end

    def terminal_key
      ENV.fetch("TBANK_TERMINAL_KEY") { raise Error, "TBANK_TERMINAL_KEY не задан" }
    end

    def password
      ENV.fetch("TBANK_PASSWORD") { raise Error, "TBANK_PASSWORD не задан" }
    end

    def post_json(url, payload)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10
      http.open_timeout = 5

      request = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
      request.body = payload.to_json

      response = http.request(request)
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise Error, "Не удалось разобрать ответ Т-Банка: #{e.message}"
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise Error, "Таймаут запроса к Т-Банку: #{e.message}"
    end
  end
end
