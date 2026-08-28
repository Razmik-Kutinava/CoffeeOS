# frozen_string_literal: true
# DEAD CODE: not called from app/ as of 2026-08-28, verify before use

require "net/http"
require "json"
require "uri"

module Shop
  # OTP доставка в WhatsApp / Telegram через HTTP API провайдера.
  # Ключи только из ENV.
  class MessengerClient
    class Error < StandardError
      attr_reader :http_status

      def initialize(message, http_status: nil)
        super(message)
        @http_status = http_status
      end
    end

    def self.deliver_otp!(to:, code:)
      new.deliver_otp!(to: to, code: code)
    end

    def deliver_otp!(to:, code:)
      if Rails.env.test? || otp_log_fallback? || api_key.blank? || api_url.blank?
        Rails.logger.info("[Shop::MessengerClient] OTP messenger sent to #{to}")
        return true
      end

      deliver_via_provider!(to: to, code: code)
    end

    private

    def deliver_via_provider!(to:, code:)
      uri = URI(api_url)
      payload = {
        phone: to,
        code: code
      }

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      return true if response.is_a?(Net::HTTPSuccess)

      Rails.logger.error("[Shop::MessengerClient] HTTP #{response.code} #{response.body}")
      raise Error.new("Не удалось отправить код в мессенджер. Попробуйте позже.", http_status: response.code.to_i)
    rescue Error
      raise
    rescue StandardError => e
      Rails.logger.error("[Shop::MessengerClient] #{e.class}: #{e.message}")
      raise Error.new("Не удалось отправить код в мессенджер. Попробуйте позже.", http_status: 502)
    end

    def api_url
      ENV["SHOP_MESSENGER_API_URL"].to_s.strip
    end

    def api_key
      ENV["SHOP_MESSENGER_API_KEY"].to_s.strip
    end

    def otp_log_fallback?
      ActiveModel::Type::Boolean.new.cast(ENV["SHOP_OTP_LOG_FALLBACK"])
    end
  end
end
