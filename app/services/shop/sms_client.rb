# frozen_string_literal: true
# DEAD CODE: not called from app/ as of 2026-08-28, verify before use

require "net/http"
require "json"
require "uri"

module Shop
  # SMS OTP через SMS.ru (или log-fallback). Ключи только из ENV.
  class SmsClient
    class Error < StandardError
      attr_reader :http_status

      def initialize(message, http_status: nil)
        super(message)
        @http_status = http_status
      end
    end

    API_URL = URI("https://sms.ru/sms/send")

    def self.deliver_otp!(to:, code:)
      new.deliver_otp!(to: to, code: code)
    end

    def deliver_otp!(to:, code:)
      if Rails.env.test? || otp_log_fallback? || api_id.blank?
        Rails.logger.info("[Shop::SmsClient] OTP SMS sent to #{to}")
        return true
      end

      deliver_via_sms_ru!(to: to, code: code)
    end

    private

    def deliver_via_sms_ru!(to:, code:)
      uri = API_URL.dup
      params = {
        api_id: api_id,
        to: to.delete_prefix("+"),
        msg: "Код CoffeeOS: #{code}. Действует 10 минут.",
        json: 1
      }
      uri.query = URI.encode_www_form(params)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error("[Shop::SmsClient] HTTP #{response.code} #{response.body}")
        raise Error.new("Не удалось отправить SMS. Попробуйте позже.", http_status: response.code.to_i)
      end

      body = JSON.parse(response.body) rescue {}
      status = body["status_code"].to_i
      if status != 100
        Rails.logger.error("[Shop::SmsClient] SMS.ru status=#{status} body=#{response.body}")
        raise Error.new("Не удалось отправить SMS. Попробуйте позже.", http_status: 502)
      end

      true
    rescue Error
      raise
    rescue StandardError => e
      Rails.logger.error("[Shop::SmsClient] #{e.class}: #{e.message}")
      raise Error.new("Не удалось отправить SMS. Попробуйте позже.", http_status: 502)
    end

    def api_id
      ENV["SHOP_SMS_RU_API_ID"].to_s.strip.presence || ENV["SMS_RU_API_ID"].to_s.strip.presence
    end

    def otp_log_fallback?
      ActiveModel::Type::Boolean.new.cast(ENV["SHOP_OTP_LOG_FALLBACK"])
    end
  end
end
