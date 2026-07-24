# frozen_string_literal: true

require "test_helper"

class Shop::EmailOtpCooldownTest < ActiveSupport::TestCase
  setup do
    @email = "cooldown-#{SecureRandom.hex(4)}@example.com"
  end

  test "email send blocked within 60 seconds" do
    Shop::EmailOtp.send_code!(email: @email)
    err = assert_raises(Shop::EmailOtp::Error) do
      Shop::EmailOtp.send_code!(email: @email)
    end
    assert_match(/60|секунд|подождите/i, err.message)
  end

  test "email send allowed after 60 seconds" do
    Shop::EmailOtp.send_code!(email: @email)
    travel 61.seconds do
      assert_nothing_raised { Shop::EmailOtp.send_code!(email: @email) }
    end
  end
end
