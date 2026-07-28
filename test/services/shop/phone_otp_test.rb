# frozen_string_literal: true

require "test_helper"

class Shop::PhoneOtpTest < ActiveSupport::TestCase
  setup do
    @phone = "+79001112233"
    ENV["SHOP_OTP_LOG_FALLBACK"] = "true"
  end

  teardown do
    ENV.delete("SHOP_OTP_LOG_FALLBACK")
  end

  test "send_code sms creates otp and invalidates previous" do
    Shop::PhoneOtp.send_code!(phone: @phone, channel: "sms")
    first = MobileOtpCode.where(phone: @phone).order(created_at: :desc).first
    assert first
    assert_equal false, first.is_used
    assert first.code.length.between?(4, 6)

    travel 61.seconds do
      Shop::PhoneOtp.send_code!(phone: @phone, channel: "sms")
    end

    first.reload
    assert_equal true, first.is_used
    assert_equal 2, MobileOtpCode.where(phone: @phone).count
  end

  test "send_code flash_call stores 4 digit code" do
    Shop::PhoneOtp.send_code!(phone: @phone, channel: "flash_call")
    record = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
    assert_equal 4, record.code.length
  end

  test "send_code messenger stores 4 digit code" do
    Shop::PhoneOtp.send_code!(phone: @phone, channel: "messenger")
    record = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
    assert record
    assert_equal 4, record.code.length
  end

  test "cooldown blocks resend within 60 seconds" do
    Shop::PhoneOtp.send_code!(phone: @phone, channel: "sms")
    err = assert_raises(Shop::PhoneOtp::Error) do
      Shop::PhoneOtp.send_code!(phone: @phone, channel: "sms")
    end
    assert_match(/60|секунд|подождите/i, err.message)
  end

  test "verify accepts code and marks used" do
    Shop::PhoneOtp.send_code!(phone: @phone, channel: "sms")
    record = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
    assert_equal @phone, Shop::PhoneOtp.verify!(phone: @phone, code: record.code)
    assert record.reload.is_used
  end

  test "verify rejects wrong code and increments attempts" do
    Shop::PhoneOtp.send_code!(phone: @phone, channel: "sms")
    assert_raises(Shop::PhoneOtp::Error) do
      Shop::PhoneOtp.verify!(phone: @phone, code: "000000")
    end
    record = MobileOtpCode.where(phone: @phone).order(created_at: :desc).first
    assert_equal 1, record.attempts
  end

  test "verify invalidates after 5 failed attempts" do
    Shop::PhoneOtp.send_code!(phone: @phone, channel: "sms")
    5.times do
      assert_raises(Shop::PhoneOtp::Error) do
        Shop::PhoneOtp.verify!(phone: @phone, code: "000000")
      end
    end
    record = MobileOtpCode.where(phone: @phone).order(created_at: :desc).first
    assert record.is_used
    assert_raises(Shop::PhoneOtp::Error) do
      Shop::PhoneOtp.verify!(phone: @phone, code: record.code)
    end
  end

  test "normalizes phone input on send" do
    Shop::PhoneOtp.send_code!(phone: "89001112233", channel: "sms")
    assert MobileOtpCode.exists?(phone: "+79001112233", is_used: false)
  end
end
