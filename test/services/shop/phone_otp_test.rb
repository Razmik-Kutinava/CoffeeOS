# frozen_string_literal: true

require "test_helper"

class Shop::PhoneOtpTest < ActiveSupport::TestCase
  setup do
    @phone = "+79001112233"
    ENV["SHOP_OTP_LOG_FALLBACK"] = "true"
    @session = {}
    @tenant_id = SecureRandom.uuid
  end

  teardown do
    ENV.delete("SHOP_OTP_LOG_FALLBACK")
  end

  test "init_callcheck stores check_id in session and returns dial fields" do
    result = Shop::PhoneOtp.init_callcheck!(phone: @phone, session: @session, tenant_id: @tenant_id)
    assert_equal @phone, result[:phone]
    assert result[:check_id].present?
    assert result[:call_phone].present?
    assert result[:call_phone_html].to_s.include?("tel:")
    assert_equal result[:check_id], @session[Shop::PhoneOtp::CALLCHECK_SESSION_KEY]["check_id"]
  end

  test "poll_callcheck pending until cache confirms 401" do
    Shop::PhoneOtp.init_callcheck!(phone: @phone, session: @session, tenant_id: @tenant_id)
    check_id = @session[Shop::PhoneOtp::CALLCHECK_SESSION_KEY]["check_id"]

    pending = Shop::PhoneOtp.poll_callcheck!(session: @session, tenant_id: @tenant_id)
    assert_equal false, pending[:confirmed]

    Rails.cache.write("sms_ru:callcheck:#{check_id}", { "status" => 401 })
    done = Shop::PhoneOtp.poll_callcheck!(session: @session, tenant_id: @tenant_id)
    assert_equal true, done[:confirmed]
    assert_equal @phone, done[:phone]
    assert_nil @session[Shop::PhoneOtp::CALLCHECK_SESSION_KEY]
  end

  test "poll_callcheck rejects foreign check_id session tenant mismatch" do
    Shop::PhoneOtp.init_callcheck!(phone: @phone, session: @session, tenant_id: @tenant_id)
    err = assert_raises(Shop::PhoneOtp::Error) do
      Shop::PhoneOtp.poll_callcheck!(session: @session, tenant_id: SecureRandom.uuid)
    end
    assert_match(/сессия|недействительн/i, err.message)
  end

  test "send_sms_code creates otp without callcheck" do
    phone = Shop::PhoneOtp.send_sms_code!(phone: @phone)
    assert_equal @phone, phone
    record = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
    assert_equal 4, record.code.length
  end

  test "verify_sms accepts code" do
    Shop::PhoneOtp.send_sms_code!(phone: @phone)
    record = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
    assert_equal @phone, Shop::PhoneOtp.verify_sms!(phone: @phone, code: record.code)
    assert record.reload.is_used
  end

  test "verify_sms rejects wrong code" do
    Shop::PhoneOtp.send_sms_code!(phone: @phone)
    assert_raises(Shop::PhoneOtp::Error) do
      Shop::PhoneOtp.verify_sms!(phone: @phone, code: "0000")
    end
  end

  test "legacy send_code rejects flash_call" do
    err = assert_raises(Shop::PhoneOtp::Error) do
      Shop::PhoneOtp.send_code!(phone: @phone, channel: "flash_call")
    end
    assert_match(/sms/i, err.message)
  end

  test "legacy send_code sms works" do
    assert_equal @phone, Shop::PhoneOtp.send_code!(phone: @phone, channel: "sms")
  end
end
