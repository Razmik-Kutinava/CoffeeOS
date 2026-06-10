# frozen_string_literal: true

module Shop
  # Отправка push через FCM HTTP v1 (legacy server key).
  class FcmClient
    class Error < StandardError; end

    API_URL = "https://fcm.googleapis.com/fcm/send"

    def self.deliver!(token:, title:, body:, data: {})
      new.deliver!(token: token, title: title, body: body, data: data)
    end

    def deliver!(token:, title:, body:, data: {})
      server_key = ENV["FCM_SERVER_KEY"].to_s.strip
      if server_key.blank?
        Rails.logger.info("[Shop::FcmClient] FCM_SERVER_KEY missing — push logged only: #{title}")
        return { stub: true }
      end

      payload = {
        to: token,
        notification: { title: title, body: body },
        data: data.transform_keys(&:to_s).transform_values(&:to_s)
      }

      response = HTTParty.post(
        API_URL,
        headers: {
          "Authorization" => "key=#{server_key}",
          "Content-Type" => "application/json"
        },
        body: payload.to_json,
        timeout: 10
      )

      unless response.success?
        raise Error, "FCM #{response.code}: #{response.body}"
      end

      parsed = JSON.parse(response.body)
      if parsed["failure"].to_i.positive?
        raise Error, "FCM failure: #{parsed['results']}"
      end

      parsed
    rescue JSON::ParserError => e
      raise Error, "FCM invalid JSON: #{e.message}"
    end
  end
end
