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
      "messenger" => 30.seconds,
      "sms" => 60.seconds
    }.freeze
    CHANNELS = %w[sms flash_call messenger].freeze

    def self.send_code!(phone:, channel:)
      new.send_code!(phone: phone, channel: channel)
    end

    def self.verify!(phone:, code:)
      new.verify!(phone: phone, code: code)
    end

    def send_code!(phone:, channel:)
      normalized = PhoneNormalizer.normalize!(phone)
      ch = channel.to_s.strip
      raise Error, "Выберите SMS, мессенджер или звонок" unless CHANNELS.include?(ch)

      enforce_cooldown!(normalized, ch)

      otp_code = nil
      ActiveRecord::Base.transaction do
        MobileOtpCode.where(phone: normalized, is_used: false).update_all(is_used: true)
        otp_code = generate_and_deliver!(phone: normalized, channel: ch)
        MobileOtpCode.create!(
          phone: normalized,
          code: otp_code,
          expires_at: CODE_TTL.from_now,
          attempts: 0,
          is_used: false
        )
      end

      normalized
    rescue PhoneNormalizer::Error => e
      raise Error, e.message
    rescue MessengerClient::Error => e
      raise MessengerDeliveryError.new(e.message, http_status: e.http_status)
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

    def generate_and_deliver!(phone:, channel:)
      if channel == "flash_call"
        code = FlashCallClient.request_call!(to: phone)
        code = code.to_s.gsub(/\D/, "").last(4)
        raise Error, "Не удалось получить код звонка" unless code.length == 4

        return code
      end

      code = generate_sms_code
      if channel == "messenger"
        MessengerClient.deliver_otp!(to: phone, code: code)
      else
        SmsClient.deliver_otp!(to: phone, code: code)
      end
      code
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
