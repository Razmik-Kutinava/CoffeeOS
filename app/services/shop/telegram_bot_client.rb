# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Shop
  # #39 — Telegram Bot API для каскада «Заказ готов» (гость, не ops alerts).
  class TelegramBotClient
    class Error < StandardError
      attr_reader :http_status

      def initialize(message, http_status: nil)
        super(message)
        @http_status = http_status
      end
    end

    class BadRequestError < Error; end
    class ForbiddenError < Error; end

    def self.send_message!(chat_id:, text:)
      new.send_message!(chat_id: chat_id, text: text)
    end

    def send_message!(chat_id:, text:)
      raise Error.new("TELEGRAM_BOT_TOKEN blank", http_status: 500) if token.blank?

      return simulate!(chat_id) if simulate?

      post_send_message!(chat_id: chat_id, text: text)
    end

    private

    def simulate!(chat_id)
      if ActiveModel::Type::Boolean.new.cast(ENV["TELEGRAM_FORCE_400"])
        raise BadRequestError.new("Telegram 400 (simulate)", http_status: 400)
      end
      if ActiveModel::Type::Boolean.new.cast(ENV["TELEGRAM_FORCE_403"])
        raise ForbiddenError.new("Telegram 403 (simulate)", http_status: 403)
      end
      if ActiveModel::Type::Boolean.new.cast(ENV["TELEGRAM_FORCE_5XX"])
        raise Error.new("Telegram 502 (simulate)", http_status: 502)
      end
      if ActiveModel::Type::Boolean.new.cast(ENV["TELEGRAM_FORCE_TIMEOUT"])
        raise Error.new("Telegram timeout (simulate)", http_status: 504)
      end

      Rails.logger.info("[Shop::TelegramBotClient] sendMessage chat_id=#{chat_id} (simulate)")
      true
    end

    def post_send_message!(chat_id:, text:)
      uri = URI("https://api.telegram.org/bot#{token}/sendMessage")
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = { chat_id: chat_id, text: text }.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                  open_timeout: 10, read_timeout: 15) do |http|
        http.request(request)
      end

      code = response.code.to_i
      raise BadRequestError.new("Telegram HTTP 400", http_status: 400) if code == 400
      raise ForbiddenError.new("Telegram HTTP 403", http_status: 403) if code == 403
      raise Error.new("Telegram HTTP #{code}", http_status: code) unless response.is_a?(Net::HTTPSuccess)

      body = JSON.parse(response.body)
      raise Error.new("Telegram ok=false", http_status: 502) unless body["ok"]

      true
    rescue JSON::ParserError
      raise Error.new("Telegram: invalid JSON", http_status: 502)
    rescue BadRequestError, ForbiddenError, Error
      raise
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise Error.new("Telegram timeout: #{e.class}", http_status: 504)
    rescue StandardError => e
      raise Error.new("Telegram: #{e.class} #{e.message}", http_status: 502)
    end

    def token
      ENV["TELEGRAM_BOT_TOKEN"].to_s.strip.presence
    end

    def simulate?
      Rails.env.test? || ActiveModel::Type::Boolean.new.cast(ENV["TELEGRAM_SIMULATE"]) || token.blank?
    end
  end
end
