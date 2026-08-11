# frozen_string_literal: true

module Callbacks
  # Входящий webhook SMS.ru: sms_status + callcheck_status.
  # Ответ контроллера обязан быть plain "100".
  # Idempotency — Rails.cache (Solid Cache на Fly), не process-local CacheCounter.
  class SmsRuWebhook
    class InvalidHashError < StandardError; end
    class PayloadTooLargeError < StandardError; end

    IDEMPOTENCY_TTL = 24.hours
    MAX_ENTRIES = 100
    MAX_ENTRY_BYTES = 4_096
    FAIL_STATUS_CODES = %w[104 105 106 107 108 150].freeze

    Result = Struct.new(:processed, :duplicates, keyword_init: true)

    def self.call!(entries:, hash:)
      new(entries: entries, hash: hash).call!
    end

    def initialize(entries:, hash:)
      list = Array(entries)
      raise PayloadTooLargeError, "too many entries" if list.size > MAX_ENTRIES

      @entries = list.map do |e|
        s = e.to_s.gsub("\r\n", "\n")
        raise PayloadTooLargeError, "entry too large" if s.bytesize > MAX_ENTRY_BYTES

        s
      end
      @hash = hash.to_s
    end

    def call!
      verify_hash!
      processed = 0
      duplicates = 0

      @entries.each do |entry|
        outcome = process_entry(entry)
        case outcome
        when :processed then processed += 1
        when :duplicate then duplicates += 1
        end
      end

      Result.new(processed: processed, duplicates: duplicates)
    end

    def self.expected_hash(api_id, entries)
      Digest::SHA256.hexdigest(api_id.to_s + Array(entries).join)
    end

    private

    def verify_hash!
      api_id = ENV["SMS_RU_API_ID"].to_s.strip
      raise InvalidHashError, "SMS_RU_API_ID blank" if api_id.blank?
      raise InvalidHashError, "hash blank" if @hash.blank?

      expected = self.class.expected_hash(api_id, @entries)
      raise InvalidHashError, "hash mismatch" unless ActiveSupport::SecurityUtils.secure_compare(expected, @hash)
    end

    def process_entry(entry)
      lines = entry.to_s.split("\n", -1)
      type = lines[0].to_s.strip
      case type
      when "sms_status"
        handle_sms_status(lines)
      when "callcheck_status"
        handle_callcheck_status(lines)
      else
        Rails.logger.info("[SmsRuWebhook] ignore type=#{type.inspect}")
        :ignored
      end
    end

    def handle_sms_status(lines)
      sms_id = lines[1].to_s.strip
      status_code = lines[2].to_s.strip
      unix_ts = lines[3].to_s.strip
      return :ignored if sms_id.blank? || status_code.blank?

      idem_key = "sms_ru:webhook:sms_status:#{sms_id}:#{status_code}:#{unix_ts}"
      return :duplicate unless claim_idempotency(idem_key)

      begin
        log = OrderNotificationLog
          .where(channel: "sms")
          .where("payload->>'sms_id' = ?", sms_id)
          .order(created_at: :desc)
          .first

        unless log
          Rails.logger.info("[SmsRuWebhook] sms_status no log sms_id=#{sms_id} status=#{status_code}")
          return :processed
        end

        Current.set(tenant_id: log.tenant_id) do
          payload = (log.payload || {}).deep_dup
          payload["delivery_status"] = status_code
          payload["delivery_status_at"] = unix_ts.presence || Time.current.to_i.to_s
          history = Array(payload["delivery_status_history"])
          history << { "status" => status_code, "at" => payload["delivery_status_at"] }
          payload["delivery_status_history"] = history.last(20)

          attrs = { payload: payload }
          if FAIL_STATUS_CODES.include?(status_code) && log.status == "sent"
            attrs[:status] = "failed"
            attrs[:error_message] = "SMS.ru delivery status #{status_code}"
          end
          log.update!(attrs)
        end

        Rails.logger.info("[SmsRuWebhook] sms_status sms_id=#{sms_id} status=#{status_code} log=#{log.id}")
        :processed
      rescue StandardError
        release_idempotency(idem_key)
        raise
      end
    end

    def handle_callcheck_status(lines)
      check_id = lines[1].to_s.strip
      check_status = lines[2].to_s.strip
      unix_ts = lines[3].to_s.strip
      return :ignored if check_id.blank? || check_status.blank?

      idem_key = "sms_ru:webhook:callcheck:#{check_id}:#{check_status}:#{unix_ts}"
      return :duplicate unless claim_idempotency(idem_key)

      begin
        # Воронка callcheck ещё не персистит check_id — пока cache + лог для ops.
        Rails.cache.write(
          "sms_ru:callcheck:#{check_id}",
          { "status" => check_status, "at" => unix_ts }.to_json,
          expires_in: 1.hour
        )
        Rails.logger.info(
          "[SmsRuWebhook] callcheck_status check_id=#{check_id} status=#{check_status} at=#{unix_ts}"
        )
        :processed
      rescue StandardError
        release_idempotency(idem_key)
        raise
      end
    end

    def claim_idempotency(key)
      Rails.cache.write(key, 1, expires_in: IDEMPOTENCY_TTL, unless_exist: true)
    end

    def release_idempotency(key)
      Rails.cache.delete(key)
    end
  end
end
