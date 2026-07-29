# frozen_string_literal: true

require "test_helper"

# RED: Shop::SmsRuClient — единый клиент SMS.ru для flash_call (/code/call) и sms (/sms/send).
# Ожидаем: класс Shop::SmsRuClient с методами request_flash_call! и send_sms!, dev-fallback.
class Shop::SmsRuClientTest < ActiveSupport::TestCase
  setup do
    ENV["SMS_RU_API_ID"] = "test-api-id-123"
    ENV["SMS_RU_FROM"] = "CoffeeOS"
    ENV["SHOP_OTP_LOG_FALLBACK"] = "true"
  end

  teardown do
    ENV.delete("SMS_RU_API_ID")
    ENV.delete("SMS_RU_FROM")
    ENV.delete("SHOP_OTP_LOG_FALLBACK")
  end

  # --- flash_call: dev fallback ---

  test "request_flash_call! returns 4-digit code in dev fallback mode" do
    code = Shop::SmsRuClient.request_flash_call!(phone: "+79001112233", ip: "1.2.3.4")
    assert_equal 4, code.length
    assert_match(/\A\d{4}\z/, code)
  end

  test "request_flash_call! accepts phone and ip keyword args" do
    assert_nothing_raised do
      Shop::SmsRuClient.request_flash_call!(phone: "+79001112233", ip: "127.0.0.1")
    end
  end

  # --- sms: dev fallback ---

  test "send_sms! succeeds in dev fallback mode" do
    assert_nothing_raised do
      Shop::SmsRuClient.send_sms!(phone: "+79001112233", code: "5678", ip: "1.2.3.4")
    end
  end

  test "send_sms! accepts phone, code and ip keyword args" do
    assert_nothing_raised do
      Shop::SmsRuClient.send_sms!(phone: "+79001112233", code: "1234", ip: "127.0.0.1")
    end
  end

  # --- error class ---

  test "SmsRuClient::Error is defined" do
    assert_kind_of Class, Shop::SmsRuClient::Error
    assert Shop::SmsRuClient::Error < StandardError
  end

  test "SmsRuClient::Error responds to http_status" do
    err = Shop::SmsRuClient::Error.new("test", http_status: 502)
    assert_equal 502, err.http_status
  end
end
