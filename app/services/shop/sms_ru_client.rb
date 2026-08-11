# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Shop
  # Единый клиент SMS.ru: flash_call, sms/*, callcheck, my/*, auth/check.
  # Ключи только из ENV: SMS_RU_API_ID, SMS_RU_FROM.
  class SmsRuClient
    class Error < StandardError
      attr_reader :http_status, :status_code

      def initialize(message, http_status: nil, status_code: nil)
        super(message)
        @http_status = http_status
        @status_code = status_code
      end
    end

    class ValidationError < Error; end

    SendResult = Struct.new(:sms_id, keyword_init: true)
    StatusResult = Struct.new(:sms_id, :status_code, :status_text, :cost, :ok, keyword_init: true)
    CostResult = Struct.new(
      :phone, :cost, :sms_count, :total_cost, :total_sms, :ok, :status_code, :status_text,
      keyword_init: true
    )
    CallcheckAddResult = Struct.new(
      :check_id, :call_phone, :call_phone_pretty, keyword_init: true
    )
    CallcheckStatusResult = Struct.new(
      :check_id, :check_status, :check_status_text, :confirmed, keyword_init: true
    )
    BalanceResult = Struct.new(:balance, keyword_init: true)
    LimitResult = Struct.new(:total_limit, :used_today, keyword_init: true)
    FreeResult = Struct.new(:total_free, :used_today, keyword_init: true)
    SendersResult = Struct.new(:senders, keyword_init: true)
    AuthCheckResult = Struct.new(:ok, :status_code, keyword_init: true)

    FLASH_CALL_URL     = URI("https://sms.ru/code/call")
    SMS_SEND_URL       = URI("https://sms.ru/sms/send")
    SMS_STATUS_URL     = URI("https://sms.ru/sms/status")
    SMS_COST_URL       = URI("https://sms.ru/sms/cost")
    CALLCHECK_ADD_URL  = URI("https://sms.ru/callcheck/add")
    CALLCHECK_STATUS_URL = URI("https://sms.ru/callcheck/status")
    MY_BALANCE_URL     = URI("https://sms.ru/my/balance")
    MY_LIMIT_URL       = URI("https://sms.ru/my/limit")
    MY_FREE_URL        = URI("https://sms.ru/my/free")
    MY_SENDERS_URL     = URI("https://sms.ru/my/senders")
    AUTH_CHECK_URL     = URI("https://sms.ru/auth/check")
    MAX_MSG_LENGTH = 70
    CALLCHECK_CONFIRMED = 401
    CALLCHECK_PENDING = 400
    CALLCHECK_EXPIRED = 402

    def self.request_flash_call!(phone:, ip: nil)
      new.request_flash_call!(phone: phone, ip: ip)
    end

    def self.send_sms!(phone:, code:, ip: nil)
      new.send_sms!(phone: phone, code: code, ip: ip)
    end

    def self.send_message!(phone:, msg:, ip: nil)
      new.send_message!(phone: phone, msg: msg, ip: ip)
    end

    def self.status!(sms_ids:)
      new.status!(sms_ids: sms_ids)
    end

    def self.cost!(phone:, msg:)
      new.cost!(phone: phone, msg: msg)
    end

    def self.callcheck_add!(phone:)
      new.callcheck_add!(phone: phone)
    end

    def self.callcheck_status!(check_id:)
      new.callcheck_status!(check_id: check_id)
    end

    def self.balance!
      new.balance!
    end

    def self.limit!
      new.limit!
    end

    def self.free!
      new.free!
    end

    def self.senders!
      new.senders!
    end

    def self.auth_check!
      new.auth_check!
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
    # #48 — возвращает SendResult(sms_id:); per-phone ERROR → Error.
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
        return SendResult.new(sms_id: "fallback-#{SecureRandom.hex(4)}")
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
      parse_sms_send_body!(body, phone: phone)
    end

    # #50 — статус по sms_id (один или массив). api_id только из ENV.
    # @return [Array<StatusResult>]
    def status!(sms_ids:)
      ids = normalize_sms_ids(sms_ids)
      if ids.empty?
        raise ValidationError.new("sms_id required", http_status: 422)
      end

      if fallback?
        Rails.logger.info("[Shop::SmsRuClient] status #{ids.join(',')} (fallback)")
        return ids.map do |id|
          StatusResult.new(
            sms_id: id,
            status_code: 103,
            status_text: "fallback",
            cost: 0,
            ok: true
          )
        end
      end

      body = post_json!(SMS_STATUS_URL, {
        "api_id" => api_id,
        "sms_id" => ids.join(","),
        "json" => "1"
      })
      parse_sms_status_body!(body, requested_ids: ids)
    end

    # #51 — оценка стоимости до отправки. api_id только ENV. Один номер (канон CoffeeOS).
    # @return [CostResult]
    def cost!(phone:, msg:)
      digits = strip_plus(phone)
      text = msg.to_s
      if digits.blank? || text.blank?
        raise ValidationError.new("phone and msg required", http_status: 422)
      end

      if fallback?
        Rails.logger.info("[Shop::SmsRuClient] cost to #{digits} (fallback)")
        return CostResult.new(
          phone: digits,
          cost: 0,
          sms_count: 1,
          total_cost: 0,
          total_sms: 1,
          ok: true,
          status_code: 100,
          status_text: "fallback"
        )
      end

      payload = {
        "api_id" => api_id,
        "to" => digits,
        "msg" => text,
        "json" => "1"
      }
      payload["from"] = sms_from if sms_from.present?

      body = post_json!(SMS_COST_URL, payload)
      parse_sms_cost_body!(body, phone: digits)
    end

    # #52 — auth: пользователь звонит на call_phone (не flash_call). Воронку PWA не меняем.
    # @return [CallcheckAddResult]
    def callcheck_add!(phone:)
      digits = strip_plus(phone)
      if digits.blank?
        raise ValidationError.new("phone required", http_status: 422)
      end

      if fallback?
        check_id = "fallback-#{SecureRandom.hex(4)}"
        Rails.logger.info("[Shop::SmsRuClient] callcheck_add #{digits} check_id=#{check_id} (fallback)")
        return CallcheckAddResult.new(
          check_id: check_id,
          call_phone: "74995555555",
          call_phone_pretty: "+7 (499) 555-55-55"
        )
      end

      body = post_json!(CALLCHECK_ADD_URL, {
        "api_id" => api_id,
        "phone" => digits,
        "json" => "1"
      })
      parse_callcheck_add_body!(body)
    end

    # @return [CallcheckStatusResult]
    def callcheck_status!(check_id:)
      id = check_id.to_s.strip
      if id.blank?
        raise ValidationError.new("check_id required", http_status: 422)
      end

      if fallback?
        Rails.logger.info("[Shop::SmsRuClient] callcheck_status #{id} (fallback)")
        return CallcheckStatusResult.new(
          check_id: id,
          check_status: CALLCHECK_PENDING,
          check_status_text: "fallback pending",
          confirmed: false
        )
      end

      body = post_json!(CALLCHECK_STATUS_URL, {
        "api_id" => api_id,
        "check_id" => id,
        "json" => "1"
      })
      parse_callcheck_status_body!(body, check_id: id)
    end

    # #53 — баланс аккаунта SMS.ru. api_id только ENV. Не shop-прокси.
    # @return [BalanceResult]
    def balance!
      if fallback?
        Rails.logger.info("[Shop::SmsRuClient] balance (fallback)")
        return BalanceResult.new(balance: 0.0)
      end

      body = post_json!(MY_BALANCE_URL, {
        "api_id" => api_id,
        "json" => "1"
      })
      parse_balance_body!(body)
    end

    # #54 — дневной лимит и used_today. api_id только ENV. Не shop-прокси.
    # @return [LimitResult]
    def limit!
      if fallback?
        Rails.logger.info("[Shop::SmsRuClient] limit (fallback)")
        return LimitResult.new(total_limit: 0, used_today: 0)
      end

      body = post_json!(MY_LIMIT_URL, {
        "api_id" => api_id,
        "json" => "1"
      })
      parse_limit_body!(body)
    end

    # #55 — бесплатные SMS на свой номер. api_id только ENV. Не shop-прокси.
    # @return [FreeResult]
    def free!
      if fallback?
        Rails.logger.info("[Shop::SmsRuClient] free (fallback)")
        return FreeResult.new(total_free: 0, used_today: 0)
      end

      body = post_json!(MY_FREE_URL, {
        "api_id" => api_id,
        "json" => "1"
      })
      parse_free_body!(body)
    end

    # #56 — список одобренных отправителей. api_id только ENV. Не shop-прокси.
    # @return [SendersResult]
    def senders!
      if fallback?
        Rails.logger.info("[Shop::SmsRuClient] senders (fallback)")
        return SendersResult.new(senders: [])
      end

      body = post_json!(MY_SENDERS_URL, {
        "api_id" => api_id,
        "json" => "1"
      })
      parse_senders_body!(body)
    end

    # #57 — проверка валидности api_id из ENV. Login/password — не используем.
    # @return [AuthCheckResult]
    def auth_check!
      if fallback?
        Rails.logger.info("[Shop::SmsRuClient] auth_check (fallback)")
        return AuthCheckResult.new(ok: true, status_code: 100)
      end

      body = post_json!(AUTH_CHECK_URL, {
        "api_id" => api_id,
        "json" => "1"
      })
      parse_auth_check_body!(body)
    end

    private

    def normalize_sms_ids(sms_ids)
      Array(sms_ids).flatten.map { |id| id.to_s.strip }.reject(&:blank?).uniq
    end

    def parse_balance_body!(body)
      ok = body["status"] == "OK" || body["status_code"].to_i == 100
      unless ok
        raise Error.new(
          "SMS.ru my/balance: status=#{body['status']} code=#{body['status_code']}",
          http_status: 502,
          status_code: body["status_code"]
        )
      end

      BalanceResult.new(balance: body["balance"].to_f)
    end

    def parse_limit_body!(body)
      ok = body["status"] == "OK" || body["status_code"].to_i == 100
      unless ok
        raise Error.new(
          "SMS.ru my/limit: status=#{body['status']} code=#{body['status_code']}",
          http_status: 502,
          status_code: body["status_code"]
        )
      end

      LimitResult.new(
        total_limit: body["total_limit"].to_i,
        used_today: body["used_today"].to_i
      )
    end

    def parse_free_body!(body)
      ok = body["status"] == "OK" || body["status_code"].to_i == 100
      unless ok
        raise Error.new(
          "SMS.ru my/free: status=#{body['status']} code=#{body['status_code']}",
          http_status: 502,
          status_code: body["status_code"]
        )
      end

      FreeResult.new(
        total_free: body["total_free"].to_i,
        used_today: body["used_today"].to_i
      )
    end

    def parse_senders_body!(body)
      ok = body["status"] == "OK" || body["status_code"].to_i == 100
      unless ok
        raise Error.new(
          "SMS.ru my/senders: status=#{body['status']} code=#{body['status_code']}",
          http_status: 502,
          status_code: body["status_code"]
        )
      end

      list = Array(body["senders"]).map(&:to_s)
      SendersResult.new(senders: list)
    end

    def parse_auth_check_body!(body)
      ok = body["status"] == "OK" || body["status_code"].to_i == 100
      unless ok
        raise Error.new(
          "SMS.ru auth/check: status=#{body['status']} code=#{body['status_code']}",
          http_status: 502,
          status_code: body["status_code"]
        )
      end

      AuthCheckResult.new(ok: true, status_code: body["status_code"].to_i)
    end

    def parse_callcheck_add_body!(body)
      ok = body["status"] == "OK" || body["status_code"].to_i == 100
      unless ok
        raise Error.new(
          "SMS.ru callcheck/add: status=#{body['status']} code=#{body['status_code']}",
          http_status: 502,
          status_code: body["status_code"]
        )
      end

      check_id = body["check_id"].presence
      call_phone = body["call_phone"].presence
      if check_id.blank? || call_phone.blank?
        raise Error.new("SMS.ru callcheck/add: empty check_id/call_phone", http_status: 502)
      end

      CallcheckAddResult.new(
        check_id: check_id,
        call_phone: call_phone,
        call_phone_pretty: body["call_phone_pretty"].presence || call_phone
      )
    end

    def parse_callcheck_status_body!(body, check_id:)
      ok = body["status"] == "OK" || body["status_code"].to_i == 100
      unless ok
        raise Error.new(
          "SMS.ru callcheck/status: status=#{body['status']} code=#{body['status_code']}",
          http_status: 502,
          status_code: body["status_code"]
        )
      end

      code = body["check_status"].to_i
      CallcheckStatusResult.new(
        check_id: check_id,
        check_status: code,
        check_status_text: body["check_status_text"].to_s,
        confirmed: code == CALLCHECK_CONFIRMED
      )
    end

    def parse_sms_cost_body!(body, phone:)
      ok = body["status"] == "OK" || body["status_code"].to_i == 100
      unless ok
        raise Error.new(
          "SMS.ru cost: status=#{body['status']} code=#{body['status_code']}",
          http_status: 502,
          status_code: body["status_code"]
        )
      end

      entry = body.dig("sms", phone) || {}
      entry_ok = entry["status"].to_s.upcase == "OK"
      CostResult.new(
        phone: phone,
        cost: entry["cost"],
        sms_count: entry["sms"],
        total_cost: body["total_cost"],
        total_sms: body["total_sms"],
        ok: entry_ok,
        status_code: entry["status_code"]&.to_i || body["status_code"]&.to_i,
        status_text: entry["status_text"].to_s
      )
    end

    def parse_sms_status_body!(body, requested_ids:)
      ok = body["status"] == "OK" || body["status_code"].to_i == 100
      unless ok
        raise Error.new(
          "SMS.ru status: status=#{body['status']} code=#{body['status_code']}",
          http_status: 502,
          status_code: body["status_code"]
        )
      end

      sms_hash = body["sms"].is_a?(Hash) ? body["sms"] : {}
      requested_ids.map do |id|
        entry = sms_hash[id]
        if entry.nil?
          StatusResult.new(
            sms_id: id,
            status_code: -1,
            status_text: "missing in response",
            cost: nil,
            ok: false
          )
        else
          entry_ok = entry["status"].to_s.upcase == "OK"
          StatusResult.new(
            sms_id: id,
            status_code: entry["status_code"].to_i,
            status_text: entry["status_text"].to_s,
            cost: entry["cost"],
            ok: entry_ok
          )
        end
      end
    end

    def parse_sms_send_body!(body, phone:)
      ok = body["status"] == "OK" || body["status_code"].to_i == 100
      unless ok
        raise Error.new(
          "SMS.ru sms: status=#{body['status']} code=#{body['status_code']}",
          http_status: 502,
          status_code: body["status_code"]
        )
      end

      digits = strip_plus(phone)
      entry = body.dig("sms", digits) || body.dig("sms", phone.to_s)
      if entry.is_a?(Hash)
        if entry["status"].to_s.upcase == "ERROR"
          code = entry["status_code"]
          text = entry["status_text"].presence || "ERROR"
          raise Error.new(
            "SMS.ru sms phone=#{digits}: #{code} #{text}",
            http_status: 502,
            status_code: code.to_i
          )
        end

        sms_id = entry["sms_id"].presence
        raise Error.new("SMS.ru sms: empty sms_id", http_status: 502) if sms_id.blank?

        return SendResult.new(sms_id: sms_id)
      end

      # Ответ без sms{} (редкий) — считаем принятым без id
      SendResult.new(sms_id: "unknown")
    end

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
