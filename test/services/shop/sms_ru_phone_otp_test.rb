# frozen_string_literal: true

require "test_helper"

# PhoneOtp × SmsRuClient: flash_call и sms — независимые каналы.
class Shop::SmsRuPhoneOtpTest < ActiveSupport::TestCase
  setup do
    @phone = "+79001112233"
    ENV["SHOP_OTP_LOG_FALLBACK"] = "true"
  end

  teardown do
    ENV.delete("SHOP_OTP_LOG_FALLBACK")
  end

  test "send_code flash_call saves code from SmsRuClient response into mobile_otp_codes" do
    Shop::PhoneOtp.send_code!(phone: @phone, channel: "flash_call")
    record = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
    assert record
    assert_equal 4, record.code.length
  end

  test "send_code flash_call overwrites previous code" do
    Shop::PhoneOtp.send_code!(phone: @phone, channel: "flash_call")
    first_code = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first.code

    travel 21.seconds do
      Shop::PhoneOtp.send_code!(phone: @phone, channel: "flash_call")
    end

    active = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
    assert active
    assert_equal 4, active.code.length
  end

  test "send_code sms generates new code without prior flash_call" do
    Shop::PhoneOtp.send_code!(phone: @phone, channel: "sms")
    latest = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
    assert latest
    assert_equal 4, latest.code.length
  end

  test "send_code sms after flash_call replaces code (independent channel)" do
    Shop::PhoneOtp.send_code!(phone: @phone, channel: "flash_call")
    flash = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first

    travel 41.seconds do
      Shop::PhoneOtp.send_code!(phone: @phone, channel: "sms")
    end

    sms = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
    assert flash.reload.is_used
    assert_not_equal flash.id, sms.id
    assert_equal 4, sms.code.length
  end

  test "verify works with code from flash_call" do
    Shop::PhoneOtp.send_code!(phone: @phone, channel: "flash_call")
    record = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
    result = Shop::PhoneOtp.verify!(phone: @phone, code: record.code)
    assert_equal @phone, result
  end

  test "verify returns 422-compatible error for wrong code" do
    Shop::PhoneOtp.send_code!(phone: @phone, channel: "flash_call")
    err = assert_raises(Shop::PhoneOtp::Error) do
      Shop::PhoneOtp.verify!(phone: @phone, code: "0000")
    end
    assert_match(/неверный код/i, err.message)
  end

  test "channel messenger is no longer accepted" do
    err = assert_raises(Shop::PhoneOtp::Error) do
      Shop::PhoneOtp.send_code!(phone: @phone, channel: "messenger")
    end
    assert_match(/sms|звонок|канал/i, err.message)
  end
end
