# frozen_string_literal: true

require "net/http"
require "net/smtp"
require "json"

module Shop
  class BrevoClient
    class Error < StandardError; end

    API_URL = URI("https://api.brevo.com/v3/smtp/email")
    SMTP_HOST = "smtp-relay.brevo.com"
    SMTP_PORT = 587

    def self.deliver_otp!(to:, code:)
      new.deliver_otp!(to: to, code: code)
    end

    def deliver_otp!(to:, code:)
      if Rails.env.test?
        Rails.logger.info("[Shop::Brevo] TEST OTP to #{to}: #{code}")
        return true
      end

      if credential.blank?
        Rails.logger.warn("[Shop::Brevo] BREVO_API_KEY missing — OTP to #{to}: #{code}")
        return true
      end

      if smtp_key?
        deliver_via_smtp!(to: to, code: code)
      else
        deliver_via_api!(to: to, code: code)
      end
    end

    private

    def deliver_via_api!(to:, code:)
      payload = {
        sender: { name: sender_name, email: mail_from },
        to: [ { email: to } ],
        subject: "Код подтверждения CoffeeOS: #{code}",
        htmlContent: otp_html(code)
      }

      request = Net::HTTP::Post.new(API_URL)
      request["api-key"] = credential
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = Net::HTTP.start(API_URL.host, API_URL.port, use_ssl: true) do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error("[Shop::Brevo] API #{response.code} #{response.body}")
        raise Error, api_error_message(response)
      end

      true
    end

    def deliver_via_smtp!(to:, code:)
      login = smtp_login
      raise Error, "Задайте BREVO_SMTP_LOGIN (логин вида 7xxxxx@smtp-brevo.com из Brevo → SMTP & API → SMTP)" if login.blank?

      message = <<~MSG
        From: #{sender_name} <#{mail_from}>
        To: <#{to}>
        Subject: =?UTF-8?B?#{Base64.strict_encode64("Код подтверждения CoffeeOS: #{code}")}?=
        MIME-Version: 1.0
        Content-Type: text/html; charset=UTF-8
        Content-Transfer-Encoding: 8bit

        #{otp_html(code)}
      MSG

      Net::SMTP.start(SMTP_HOST, SMTP_PORT, SMTP_HOST, login, credential, :plain) do |smtp|
        smtp.enable_starttls
        smtp.send_message(message, mail_from, to)
      end

      true
    rescue Net::SMTPAuthenticationError
      raise Error, "Brevo SMTP: неверный логин или SMTP-ключ. Проверьте BREVO_SMTP_LOGIN и xsmtpsib-ключ в Brevo → SMTP & API → SMTP"
    rescue Net::SMTPError => e
      Rails.logger.error("[Shop::Brevo] SMTP #{e.class}: #{e.message}")
      raise Error, "Не удалось отправить письмо через Brevo SMTP"
    end

    def api_error_message(response)
      if response.code.to_i == 401
        return "Brevo API: неверный ключ. Нужен xkeysib-... из Brevo → API Keys (не xsmtpsib SMTP-ключ)"
      end

      "Не удалось отправить письмо. Попробуйте позже."
    end

    def otp_html(code)
      <<~HTML
        <p>Ваш код для оформления заказа: <strong>#{code}</strong></p>
        <p>Код действует 10 минут.</p>
      HTML
    end

    def credential
      ENV["BREVO_API_KEY"].to_s.strip
    end

    def smtp_key?
      credential.start_with?("xsmtpsib")
    end

    def smtp_login
      ENV["BREVO_SMTP_LOGIN"].to_s.strip
    end

    def mail_from
      ENV.fetch("MAIL_FROM") do
        raise Error, "MAIL_FROM не задан"
      end
    end

    def sender_name
      ENV.fetch("MAIL_FROM_NAME", "CoffeeOS")
    end
  end
end
