# frozen_string_literal: true

module Shop
  # Phone auth: Callcheck (primary) + SMS OTP (fallback only). No /code/call in this flow.
  class PhoneOtp
    class Error < StandardError; end

    CODE_TTL = 10.minutes
    MAX_ATTEMPTS = 5
    CALLCHECK_SESSION_KEY = :shop_phone_callcheck
    CALLCHECK_TTL = 5.minutes

    def self.init_callcheck!(phone:, session:, tenant_id:)
      new.init_callcheck!(phone: phone, session: session, tenant_id: tenant_id)
    end

    def self.poll_callcheck!(session:, tenant_id:)
      new.poll_callcheck!(session: session, tenant_id: tenant_id)
    end

    def self.clear_callcheck!(session)
      session.delete(CALLCHECK_SESSION_KEY)
    end

    def self.send_sms_code!(phone:, ip: nil)
      new.send_sms_code!(phone: phone, ip: ip)
    end

    def self.verify_sms!(phone:, code:)
      new.verify_sms!(phone: phone, code: code)
    end

    # Legacy aliases used by Profile link / old callers → SMS only.
    def self.send_code!(phone:, channel:, ip: nil)
      ch = channel.to_s.strip
      raise Error, "Выберите SMS" unless ch == "sms"

      send_sms_code!(phone: phone, ip: ip)
    end

    def self.verify!(phone:, code:)
      verify_sms!(phone: phone, code: code)
    end

    def init_callcheck!(phone:, session:, tenant_id:)
      normalized = PhoneNormalizer.normalize!(phone)
      result = SmsRuClient.callcheck_add!(phone: normalized)

      session[CALLCHECK_SESSION_KEY] = {
        "phone" => normalized,
        "check_id" => result.check_id.to_s,
        "tenant_id" => tenant_id.to_s,
        "created_at" => Time.current.to_i
      }

      {
        phone: normalized,
        check_id: result.check_id.to_s,
        call_phone: result.call_phone.to_s,
        call_phone_pretty: result.call_phone_pretty.to_s,
        call_phone_html: result.call_phone_html.presence || build_call_phone_html(result.call_phone, result.call_phone_pretty)
      }
    rescue PhoneNormalizer::Error => e
      raise Error, e.message
    rescue SmsRuClient::Error => e
      raise Error, e.message
    end

    def poll_callcheck!(session:, tenant_id:)
      attempt = session[CALLCHECK_SESSION_KEY]
      raise Error, "Нет активной проверки звонка. Начните снова." if attempt.blank?

      phone = attempt["phone"].to_s
      check_id = attempt["check_id"].to_s
      raise Error, "Нет активной проверки звонка. Начните снова." if phone.blank? || check_id.blank?

      if attempt["tenant_id"].to_s != tenant_id.to_s
        raise Error, "Сессия проверки недействительна"
      end

      created_at = attempt["created_at"].to_i
      if created_at.positive? && created_at < CALLCHECK_TTL.ago.to_i
        session.delete(CALLCHECK_SESSION_KEY)
        raise Error, "Время на звонок истекло. Запросите снова или SMS."
      end

      status = SmsRuClient.callcheck_status!(check_id: check_id)
      if status.confirmed
        session.delete(CALLCHECK_SESSION_KEY)
        return { confirmed: true, phone: phone, check_status: status.check_status }
      end

      if status.check_status.to_i == SmsRuClient::CALLCHECK_EXPIRED
        session.delete(CALLCHECK_SESSION_KEY)
        return { confirmed: false, phone: phone, check_status: status.check_status, expired: true }
      end

      { confirmed: false, phone: phone, check_status: status.check_status, expired: false }
    rescue SmsRuClient::Error => e
      raise Error, e.message
    end

    def send_sms_code!(phone:, ip: nil)
      normalized = PhoneNormalizer.normalize!(phone)
      otp_code = format("%04d", SecureRandom.random_number(10_000))

      ActiveRecord::Base.transaction do
        MobileOtpCode.where(phone: normalized, is_used: false).update_all(is_used: true)
        MobileOtpCode.create!(
          phone: normalized,
          code: otp_code,
          expires_at: CODE_TTL.from_now,
          attempts: 0,
          is_used: false
        )
      end

      # Не логируем сам код.
      SmsRuClient.send_sms!(phone: normalized, code: otp_code, ip: ip)
      normalized
    rescue PhoneNormalizer::Error => e
      raise Error, e.message
    rescue SmsRuClient::Error => e
      raise Error, e.message
    end

    def verify_sms!(phone:, code:)
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

    def build_call_phone_html(call_phone, pretty)
      digits = call_phone.to_s.gsub(/\D/, "")
      return "" if digits.blank?

      tel = digits.start_with?("7") ? "+#{digits}" : "+#{digits}"
      label = ERB::Util.html_escape(pretty.presence || tel)
      %(<a href="tel:#{tel}">#{label}</a>)
    end

    def same_code?(stored, input)
      return false if stored.blank? || input.blank?
      return false unless stored.length == input.length

      ActiveSupport::SecurityUtils.secure_compare(stored, input)
    end
  end
end
