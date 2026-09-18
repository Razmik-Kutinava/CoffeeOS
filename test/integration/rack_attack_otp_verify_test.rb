# frozen_string_literal: true

require "test_helper"

# TASK_93-I — throttle verify_sms / legacy verify / email verify
class RackAttackOtpVerifyTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "otp-atk-#{SecureRandom.hex(3)}")
    @phone = "+7900#{SecureRandom.random_number(10_000_000).to_s.rjust(7, "0")}"
    @email = "otp-atk-#{SecureRandom.hex(3)}@example.com"
    ENV["SHOP_OTP_LOG_FALLBACK"] = "true"
  end

  teardown do
    ENV.delete("SHOP_OTP_LOG_FALLBACK")
  end

  test "T-I2a verify_sms exceeds limit returns 429 RATE_LIMIT_EXCEEDED" do
    with_rack_attack do
      ip = "203.0.113.40"
      5.times do
        post "/shop/api/phone_otp/verify_sms",
          headers: shop_tenant_headers(@tenant.id).merge("REMOTE_ADDR" => ip),
          params: { phone: @phone, code: "000000" },
          as: :json
        assert_includes [ 422, 401, 404 ], response.status, response.body
      end

      post "/shop/api/phone_otp/verify_sms",
        headers: shop_tenant_headers(@tenant.id).merge("REMOTE_ADDR" => ip),
        params: { phone: @phone, code: "000000" },
        as: :json
      assert_response :too_many_requests
      body = JSON.parse(response.body)
      assert_equal "RATE_LIMIT_EXCEEDED", body.dig("error", "code")
    end
  end

  test "T-I2b under limit verify_sms is not 429" do
    with_rack_attack do
      post "/shop/api/phone_otp/verify_sms",
        headers: shop_tenant_headers(@tenant.id).merge("REMOTE_ADDR" => "203.0.113.41"),
        params: { phone: @phone, code: "000000" },
        as: :json
      refute_equal 429, response.status
    end
  end

  test "T-I2c different IPs same phone still hit phone throttle" do
    with_rack_attack do
      5.times do |i|
        post "/shop/api/phone_otp/verify_sms",
          headers: shop_tenant_headers(@tenant.id).merge("REMOTE_ADDR" => "203.0.113.#{50 + i}"),
          params: { phone: @phone, code: "000000" },
          as: :json
        assert_includes [ 422, 401, 404 ], response.status
      end

      post "/shop/api/phone_otp/verify_sms",
        headers: shop_tenant_headers(@tenant.id).merge("REMOTE_ADDR" => "203.0.113.99"),
        params: { phone: @phone, code: "000000" },
        as: :json
      assert_response :too_many_requests
    end
  end

  test "T-I2d legacy phone_otp/verify is throttled" do
    with_rack_attack do
      ip = "203.0.113.60"
      5.times do
        post "/shop/api/phone_otp/verify",
          headers: shop_tenant_headers(@tenant.id).merge("REMOTE_ADDR" => ip),
          params: { phone: @phone, code: "000000" },
          as: :json
        assert_includes [ 422, 401, 404 ], response.status
      end

      post "/shop/api/phone_otp/verify",
        headers: shop_tenant_headers(@tenant.id).merge("REMOTE_ADDR" => ip),
        params: { phone: @phone, code: "000000" },
        as: :json
      assert_response :too_many_requests
    end
  end

  test "T-I2e email_otp/verify is throttled" do
    with_rack_attack do
      ip = "203.0.113.70"
      5.times do
        post "/shop/api/email_otp/verify",
          headers: shop_tenant_headers(@tenant.id).merge("REMOTE_ADDR" => ip),
          params: { email: @email, code: "000000" },
          as: :json
        assert_includes [ 422, 401, 404 ], response.status
      end

      post "/shop/api/email_otp/verify",
        headers: shop_tenant_headers(@tenant.id).merge("REMOTE_ADDR" => ip),
        params: { email: @email, code: "000000" },
        as: :json
      assert_response :too_many_requests
    end
  end
end
