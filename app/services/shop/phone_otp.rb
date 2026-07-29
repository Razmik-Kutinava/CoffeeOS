# frozen_string_literal: true

module Shop
  class PhoneOtp
    class Error < StandardError; end

    class MessengerDeliveryError < Error
      attr_reader :http_status

      def initialize(message, http_status: nil)
        super(message)
        @http_status = http_status
      end
    end

    CODE_TTL = 10.minutes
    MAX_ATTEMPTS = 5
    COOLDOWNS = {
      "flash_call" => 20.seconds,
      "sms" => 60.seconds
    }.freeze
    CHANNELS = %w[sms flash_call].freeze

    def self.send_code!(phone:, channel:, ip: nil)
      new.send_code!(phone: phone, channel: channel, ip: ip)
    end

    def self.verify!(phone:, code:)
      new.verify!(phone: phone, code: code)
    end

    def send_code!(phone:, channel:, ip: nil)
      normalized = PhoneNormalizer.normalize!(phone)
      ch = channel.to_s.strip
      raise Error, "Выберите SMS или звонок" unless CHANNELS.include?(ch)

      enforce_cooldown!(normalized, ch) unless ch == "sms"

      if ch == "flash_call"
        send_flash_call!(normalized, ip)
      else
        send_sms_with_existing_code!(normalized, ip)
      end

      normalized
    rescue PhoneNormalizer::Error => e
      raise Error, e.message
    rescue SmsRuClient::Error => e
      raise Error, e.message
    rescue SmsClient::Error, FlashCallClient::Error => e
      raise Error, e.message
    end

    def verify!(phone:, code:)
      normalized = PhoneNormalizer.normalize!(phone)
      input = code.to_s.gsub(/\D/, "")
      raise Error, "Введите код" if input.blank?
      raise Error, "Неверный код" unless input.length.between?(4, 6)

      record = MobileOtpCode.active.where(phone: normalized).order(created_at: :desc).first
      raise Error, "Код не найден или истёк. Запросите новый." unless record

      if record.attempts >= MAX_ATTEMPTS
        record.update!(is_used: true)
        raise Error, "Слишком много попыток. Запросите новый код."
      end

      record.increment!(:attempts)

      unless same_code?(record.code, input)
        if record.attempts >= MAX_ATTEMPTS
          record.update!(is_used: true)
          raise Error, "Слишком много попыток. Запросите новый код."
        end
        raise Error, "Неверный код"
      end

      record.update!(is_used: true)
      normalized
    rescue PhoneNormalizer::Error => e
      raise Error, e.message
    end

    private

    def enforce_cooldown!(normalized_phone, channel)
      cooldown = COOLDOWNS.fetch(channel, 60.seconds)
      last = MobileOtpCode.where(phone: normalized_phone).order(created_at: :desc).first
      return if last.nil?
      return if last.created_at <= cooldown.ago

      seconds = cooldown.to_i
      raise Error, "Подождите #{seconds} секунд перед повторной отправкой кода"
    end

    def send_flash_call!(phone, ip)
      otp_code = SmsRuClient.request_flash_call!(phone: phone, ip: ip)
      otp_code = otp_code.to_s.gsub(/\D/, "").last(4)
      raise Error, "Не удалось получить код звонка" unless otp_code.length == 4

      ActiveRecord::Base.transaction do
        MobileOtpCode.where(phone: phone, is_used: false).update_all(is_used: true)
        MobileOtpCode.create!(
          phone: phone,
          code: otp_code,
          expires_at: CODE_TTL.from_now,
          attempts: 0,
          is_used: false
        )
      end
    end

    # SMS переиспользует последний активный код (не генерирует новый)
    def send_sms_with_existing_code!(phone, ip)
      record = MobileOtpCode.active.where(phone: phone).order(created_at: :desc).first
      raise Error, "Нет активного кода. Запросите звонок сначала." unless record

      SmsRuClient.send_sms!(phone: phone, code: record.code, ip: ip)
    end

    def generate_sms_code
      return "1234" if Rails.env.test?

      format("%04d", SecureRandom.random_number(10_000))
    end

    def same_code?(stored, input)
      return false if stored.blank? || input.blank?
      return false unless stored.length == input.length

      ActiveSupport::SecurityUtils.secure_compare(stored, input)
    end
  end
end
