# frozen_string_literal: true

require "jwt"
require "net/http"
require "json"
require "openssl"

module Shop
  # Отправка push через Firebase Cloud Messaging HTTP v1.
  class FcmClient
    class Error < StandardError; end

    OAUTH_URL = URI("https://oauth2.googleapis.com/token")
    FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"

    def self.deliver!(token:, title:, body:, data: {})
      new.deliver!(token: token, title: title, body: body, data: data)
    end

    def deliver!(token:, title:, body:, data: {})
      if simulate?
        Rails.logger.info("[Shop::FcmClient] FCM_SIMULATE — #{title}: #{body} (token=#{token.to_s.first(12)}…)")
        return { simulated: true, token: token }
      end

      account = Shop::FirebaseConfig.service_account
      project_id = Shop::FirebaseConfig.project_id

      if account.blank? || project_id.blank?
        Rails.logger.info("[Shop::FcmClient] FIREBASE_SERVICE_ACCOUNT_JSON missing — push logged only: #{title}")
        return { stub: true }
      end

      access_token = fetch_access_token!(account)
      send_message!(
        project_id: project_id,
        access_token: access_token,
        token: token,
        title: title,
        body: body,
        data: data
      )
    end

    private

    def simulate?
      ActiveModel::Type::Boolean.new.cast(ENV["FCM_SIMULATE"])
    end

    # FCM data values must be strings; arrays/hashes → JSON (SW parseNotificationActions).
    def stringify_fcm_data(data)
      data.to_h.transform_keys(&:to_s).transform_values do |value|
        case value
        when Array, Hash then JSON.generate(value)
        else value.to_s
        end
      end
    end

    def fetch_access_token!(account)
      client_email = account["client_email"]
      private_key_pem = account["private_key"]
      raise Error, "service account missing client_email or private_key" if client_email.blank? || private_key_pem.blank?

      private_key = OpenSSL::PKey::RSA.new(private_key_pem)
      now = Time.now.to_i
      assertion = JWT.encode(
        {
          iss: client_email,
          sub: client_email,
          aud: OAUTH_URL.to_s,
          iat: now,
          exp: now + 3600,
          scope: FCM_SCOPE
        },
        private_key,
        "RS256"
      )

      response = post_form(
        OAUTH_URL,
        "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion" => assertion
      )
      parsed = JSON.parse(response.body)
      token = parsed["access_token"]
      raise Error, "OAuth token missing: #{parsed}" if token.blank?

      token
    end

    def send_message!(project_id:, access_token:, token:, title:, body:, data:)
      uri = URI("https://fcm.googleapis.com/v1/projects/#{project_id}/messages:send")
      payload = {
        message: {
          token: token,
          notification: { title: title, body: body },
          data: stringify_fcm_data(data)
        }
      }

      response = post_json(uri, payload, "Authorization" => "Bearer #{access_token}")
      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "FCM v1 #{response.code}: #{response.body}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise Error, "FCM v1 invalid JSON: #{e.message}"
    end

    def post_form(uri, form)
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(form)
      http_request(uri, request)
    end

    def post_json(uri, body, headers = {})
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      headers.each { |k, v| request[k] = v }
      request.body = body.to_json
      http_request(uri, request)
    end

    def http_request(uri, request)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 15) do |http|
        http.request(request)
      end
    end
  end
end
