# frozen_string_literal: true

require "test_helper"

class Shop::BrevoClientTest < ActiveSupport::TestCase
  test "deliver_otp! succeeds in test env without logging the code" do
    code = "654321"
    logs = capture_brevo_logs do
      assert Shop::BrevoClient.deliver_otp!(to: "otp-test@example.com", code: code)
    end

    assert_match(/TEST OTP sent to otp-test@example.com/, logs)
    refute_includes logs, code
  end

  private

  def capture_brevo_logs
    io = StringIO.new
    old = Rails.logger
    Rails.logger = Logger.new(io)
    yield
    io.string
  ensure
    Rails.logger = old
  end
end
