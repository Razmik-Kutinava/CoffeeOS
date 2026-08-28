# frozen_string_literal: true

require "test_helper"

class Shop::EmailOtpTest < ActiveSupport::TestCase
  test "send_code creates otp record" do
    email = "otp-send@example.com"
    assert_difference -> { ShopEmailOtpCode.count }, 1 do
      Shop::EmailOtp.send_code!(email: email)
    end
  end

  test "verify accepts test code" do
    email = "otp-verify@example.com"
    Shop::EmailOtp.send_code!(email: email)
    assert_equal email, Shop::EmailOtp.verify!(email: email, code: "123456")
  end

  test "verify rejects wrong code" do
    email = "otp-wrong@example.com"
    Shop::EmailOtp.send_code!(email: email)
    assert_raises(Shop::EmailOtp::Error) do
      Shop::EmailOtp.verify!(email: email, code: "000000")
    end
  end

  test "send_code survives Brevo error when otp log fallback enabled" do
    ENV["SHOP_OTP_LOG_FALLBACK"] = "true"
    original = Shop::BrevoClient.method(:deliver_otp!)
    Shop::BrevoClient.define_singleton_method(:deliver_otp!) do |**_|
      raise Shop::BrevoClient::Error, "simulated"
    end

    email = "fallback-#{SecureRandom.hex(4)}@example.com"
    assert_difference -> { ShopEmailOtpCode.count }, 1 do
      assert_equal email, Shop::EmailOtp.send_code!(email: email)
    end
    assert_equal email, Shop::EmailOtp.verify!(email: email, code: "123456")
  ensure
    Shop::BrevoClient.define_singleton_method(:deliver_otp!, original)
    ENV.delete("SHOP_OTP_LOG_FALLBACK")
  end
end
