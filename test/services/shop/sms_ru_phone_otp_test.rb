# frozen_string_literal: true

require "test_helper"

# PhoneOtp × SmsRuClient: Callcheck + SMS fallback (no /code/call in auth).
class Shop::SmsRuPhoneOtpTest < ActiveSupport::TestCase
  setup do
    @phone = "+79001112233"
    ENV["SHOP_OTP_LOG_FALLBACK"] = "true"
    @session = {}
    @tenant_id = SecureRandom.uuid
  end

  teardown do
    ENV.delete("SHOP_OTP_LOG_FALLBACK")
  end

  test "init_callcheck uses callcheck_add not flash" do
    result = Shop::PhoneOtp.init_callcheck!(phone: @phone, session: @session, tenant_id: @tenant_id)
    assert result[:check_id].present?
    assert_equal 0, MobileOtpCode.where(phone: @phone).count
  end

  test "send_sms_code generates new 4 digit otp" do
    Shop::PhoneOtp.send_sms_code!(phone: @phone)
    latest = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
    assert_equal 4, latest.code.length
  end

  test "verify_sms works with sms code" do
    Shop::PhoneOtp.send_sms_code!(phone: @phone)
    record = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
    assert_equal @phone, Shop::PhoneOtp.verify_sms!(phone: @phone, code: record.code)
  end
end
