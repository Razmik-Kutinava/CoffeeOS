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
end
