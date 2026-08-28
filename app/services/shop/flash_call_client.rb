# frozen_string_literal: true
# DEAD CODE: not called from app/ as of 2026-08-28, verify before use

require "net/http"
require "json"
require "uri"

module Shop
  # Flash Call (звонок-сброс). Код = последние 4 цифры номера звонящего.
  # Провайдер: ENV SHOP_FLASHCALL_* (Zvonok-style). Без ключей / log-fallback — код в лог.
  class FlashCallClient
    class Error < StandardError
      attr_reader :http_status

      def initialize(message, http_status: nil)
        super(message)
        @http_status = http_status
      end
    end

    def self.request_call!(to:)
      new.request_call!(to: to)
    end

    # @return [String] 4-digit code
    def request_call!(to:)
      if Rails.env.test? || otp_log_fallback? || api_key.blank?
        code = test_or_fallback_code
        Rails.logger.info("[Shop::FlashCallClient] Flash Call sent to #{to}")
        return code
      end

      request_via_provider!(to: to)
    end

    private

    def request_via_provider!(to:)
      uri = URI(api_url)
      payload = {
        phone: to.delete_prefix("+"),
        campaign_id: campaign_id
      }.compact

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}" if bearer?
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error("[Shop::FlashCallClient] HTTP #{response.code} #{response.body}")
        raise Error.new("Не удалось заказать звонок. Попробуйте позже.", http_status: response.code.to_i)
      end

      body = JSON.parse(response.body) rescue {}
      code = extract_code(body)
      raise Error.new("Провайдер не вернул код звонка", http_status: 502) if code.blank?

      code
    rescue Error
      raise
    rescue StandardError => e
      Rails.logger.error("[Shop::FlashCallClient] #{e.class}: #{e.message}")
      raise Error.new("Не удалось заказать звонок. Попробуйте позже.", http_status: 502)
    end

    def extract_code(body)
      raw = body["pin"].presence || body["code"].presence || body["caller_phone"].presence || body.dig("data", "pin")
      digits = raw.to_s.gsub(/\D/, "")
      return digits.last(4) if digits.length >= 4

      nil
    end

    def test_or_fallback_code
      return "1234" if Rails.env.test?

      format("%04d", SecureRandom.random_number(10_000))
    end

    def api_url
      ENV.fetch("SHOP_FLASHCALL_API_URL", "https://zvonok.com/manager/cabapi_external/api/v1/phones/flashcall/")
    end

    def api_key
      ENV["SHOP_FLASHCALL_API_KEY"].to_s.strip.presence
    end

    def campaign_id
      ENV["SHOP_FLASHCALL_CAMPAIGN_ID"].to_s.strip.presence
    end

    def bearer?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("SHOP_FLASHCALL_BEARER", "true"))
    end

    def otp_log_fallback?
      ActiveModel::Type::Boolean.new.cast(ENV["SHOP_OTP_LOG_FALLBACK"])
    end
  end
end
