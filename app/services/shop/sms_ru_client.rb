# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Shop
  # Единый клиент SMS.ru: flash_call (/code/call) и sms (/sms/send).
  # Ключи только из ENV: SMS_RU_API_ID, SMS_RU_FROM.
  class SmsRuClient
    class Error < StandardError
      attr_reader :http_status

      def initialize(message, http_status: nil)
        super(message)
        @http_status = http_status
      end
    end

    class ValidationError < Error; end

    FLASH_CALL_URL = URI("https://sms.ru/code/call")
    SMS_SEND_URL   = URI("https://sms.ru/sms/send")
    MAX_MSG_LENGTH = 70

    def self.request_flash_call!(phone:, ip: nil)
      new.request_flash_call!(phone: phone, ip: ip)
    end

    def self.send_sms!(phone:, code:, ip: nil)
      new.send_sms!(phone: phone, code: code, ip: ip)
    end

    def self.send_message!(phone:, msg:, ip: nil)
      new.send_message!(phone: phone, msg: msg, ip: ip)
    end

    # @return [String] 4-значный код из ответа SMS.ru
    def request_flash_call!(phone:, ip: nil)
      if fallback?
        code = test_code
        Rails.logger.info("[Shop::SmsRuClient] flash_call to #{phone}: code=#{code} (fallback)")
        return code
      end

      payload = { "api_id" => api_id, "phone" => strip_plus(phone), "json" => "1" }
      payload["ip"] = ip if ip.present?

      body = post_json!(FLASH_CALL_URL, payload)
      raise Error.new("SMS.ru flash_call: status=#{body['status']}", http_status: 502) unless body["status"] == "OK"

      raw = body["code"].to_s.gsub(/\D/, "")
      code = raw.last(4)
      raise Error.new("SMS.ru не вернул код звонка", http_status: 502) unless code.length == 4

      code
    end

    def send_sms!(phone:, code:, ip: nil)
      send_message!(phone: phone, msg: "Ваш код: #{code}", ip: ip)
    end

    # #39 — произвольный текст (каскад «Заказ готов»); ≤70 символов до HTTP.
    def send_message!(phone:, msg:, ip: nil)
      text = msg.to_s
      if text.length > MAX_MSG_LENGTH
        raise ValidationError.new(
          "SMS msg length #{text.length} > #{MAX_MSG_LENGTH}",
          http_status: 422
        )
      end

      if fallback?
        Rails.logger.info("[Shop::SmsRuClient] sms to #{phone}: msg=#{text.truncate(40)} (fallback)")
        return true
      end

      payload = {
        "api_id" => api_id,
        "to" => strip_plus(phone),
        "msg" => text,
        "from" => sms_from,
        "json" => "1"
      }
      payload["ip"] = ip if ip.present?

      body = post_json!(SMS_SEND_URL, payload)
      ok = body["status"] == "OK" || body["status_code"].to_i == 100
      raise Error.new("SMS.ru sms: status=#{body['status']}", http_status: 502) unless ok

      true
    end

    private

    def post_json!(uri, params)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request.body = URI.encode_www_form(params)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                  open_timeout: 10, read_timeout: 15) do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise Error.new("SMS.ru HTTP #{response.code}", http_status: response.code.to_i)
      end

      JSON.parse(response.body)
    rescue JSON::ParserError
      raise Error.new("SMS.ru: невалидный JSON", http_status: 502)
    rescue Error
      raise
    rescue StandardError => e
      raise Error.new("SMS.ru: #{e.class} #{e.message}", http_status: 502)
    end

    def fallback?
      Rails.env.test? || otp_log_fallback? || api_id.blank?
    end

    def test_code
      return "1234" if Rails.env.test?
      format("%04d", SecureRandom.random_number(10_000))
    end

    def api_id
      ENV["SMS_RU_API_ID"].to_s.strip.presence
    end

    def sms_from
      ENV["SMS_RU_FROM"].to_s.strip.presence || ENV["SMS_RU_SENDER"].to_s.strip.presence
    end

    def otp_log_fallback?
      ActiveModel::Type::Boolean.new.cast(ENV["SHOP_OTP_LOG_FALLBACK"])
    end

    def strip_plus(phone)
      phone.to_s.delete_prefix("+")
    end
  end
end
