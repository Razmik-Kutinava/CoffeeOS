# frozen_string_literal: true

module Shop
  class EmailOtp
    class Error < StandardError; end

    CODE_TTL = 10.minutes
    MAX_ATTEMPTS = 5
    EMAIL_FORMAT = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

    def self.send_code!(email:)
      new.send_code!(email: email)
    end

    def self.verify!(email:, code:)
      new.verify!(email: email, code: code)
    end

    def send_code!(email:)
      normalized = EmailVerificationSession.normalize(email)
      raise Error, "Укажите корректный email" unless normalized.match?(EMAIL_FORMAT)

      ShopEmailOtpCode.where(email: normalized, is_used: false).update_all(is_used: true)

      otp_code = generate_code
      ShopEmailOtpCode.create!(
        email: normalized,
        code: otp_code,
        expires_at: CODE_TTL.from_now
      )

      deliver_otp_email!(to: normalized, code: otp_code)
      normalized
    rescue BrevoClient::Error => e
      raise Error, e.message
    end

    def verify!(email:, code:)
      normalized = EmailVerificationSession.normalize(email)
      input = code.to_s.strip
      raise Error, "Введите код" if input.blank?

      record = ShopEmailOtpCode.active(normalized).order(created_at: :desc).first
      raise Error, "Код не найден или истёк. Запросите новый." unless record

      if record.attempts >= MAX_ATTEMPTS
        record.update!(is_used: true)
        raise Error, "Слишком много попыток. Запросите новый код."
      end

      record.increment!(:attempts)

      unless ActiveSupport::SecurityUtils.secure_compare(record.code, input.gsub(/\D/, "").last(6).rjust(6, "0"))
        raise Error, "Неверный код"
      end

      record.update!(is_used: true)
      normalized
    end

    private

    def generate_code
      return "123456" if Rails.env.test?

      format("%06d", SecureRandom.random_number(1_000_000))
    end

    def deliver_otp_email!(to:, code:)
      BrevoClient.deliver_otp!(to: to, code: code)
    rescue BrevoClient::Error => e
      if otp_log_fallback?
        Rails.logger.warn("[Shop::EmailOtp] Brevo недоступен (#{e.message}) — OTP для #{to}: #{code}")
        return
      end

      raise e
    end

    def otp_log_fallback?
      ActiveModel::Type::Boolean.new.cast(ENV["SHOP_OTP_LOG_FALLBACK"])
    end
  end
end
