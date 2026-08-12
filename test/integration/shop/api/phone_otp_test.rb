# frozen_string_literal: true

require "test_helper"

class Shop::Api::PhoneOtpTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!
    @phone = "+79009876543"
    ENV["SHOP_OTP_LOG_FALLBACK"] = "true"
  end

  teardown do
    ENV.delete("SHOP_OTP_LOG_FALLBACK")
  end

  test "init_callcheck then check_status confirmed returns refresh_token" do
    post "/shop/api/phone_otp/init_callcheck",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: "89009876543" },
      as: :json
    assert_response :success, response.body
    body = response.parsed_body
    assert_equal "+79009876543", body["phone"]
    assert body["check_id"].present?
    assert body["call_phone_html"].to_s.include?("tel:")

    Rails.cache.write("sms_ru:callcheck:#{body['check_id']}", { "status" => 401 })

    get "/shop/api/phone_otp/check_status",
      headers: shop_tenant_headers(@tenant.id),
      as: :json
    assert_response :success, response.body
    done = response.parsed_body
    assert_equal true, done["confirmed"]
    assert done["refresh_token"].present?
    assert MobileCustomer.exists?(phone: "+79009876543")
  end

  test "send_sms verify_sms happy path" do
    post "/shop/api/phone_otp/send_sms",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: @phone },
      as: :json
    assert_response :success, response.body

    record = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
    assert record

    post "/shop/api/phone_otp/verify_sms",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: @phone, code: record.code },
      as: :json
    assert_response :success, response.body
    assert_equal true, response.parsed_body["verified"]
    assert response.parsed_body["refresh_token"].present?
  end

  test "verify_sms wrong code is 422" do
    post "/shop/api/phone_otp/send_sms",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: @phone },
      as: :json
    assert_response :success

    post "/shop/api/phone_otp/verify_sms",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: @phone, code: "0000" },
      as: :json
    assert_response :unprocessable_entity
  end

  test "send rejects invalid phone on send_sms" do
    post "/shop/api/phone_otp/send_sms",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: "123" },
      as: :json
    assert_response :unprocessable_entity
  end

  test "legacy send flash_call rejected" do
    post "/shop/api/phone_otp/send",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: @phone, channel: "flash_call" },
      as: :json
    assert_response :unprocessable_entity
  end

  test "rack attack throttles init_callcheck by 20 seconds" do
    with_rack_attack do
      post "/shop/api/phone_otp/init_callcheck",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: @phone },
        as: :json
      assert_response :success

      post "/shop/api/phone_otp/init_callcheck",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: @phone },
        as: :json
      assert_response :too_many_requests
    end
  end

  test "rack attack throttles send_sms by 60 seconds" do
    with_rack_attack do
      post "/shop/api/phone_otp/send_sms",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: @phone },
        as: :json
      assert_response :success

      post "/shop/api/phone_otp/send_sms",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: @phone },
        as: :json
      assert_response :too_many_requests
    end
  end

  test "check_status without init is 422" do
    get "/shop/api/phone_otp/check_status",
      headers: shop_tenant_headers(@tenant.id),
      as: :json
    assert_response :unprocessable_entity
  end

  test "links phone onto email-verified session via verify_sms" do
    email = "phone-api-link-#{SecureRandom.hex(3)}@example.com"
    verify_shop_email!(tenant_id: @tenant.id, email: email)
    customer = MobileCustomer.find_by!(email: email)

    post "/shop/api/phone_otp/send_sms",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: @phone },
      as: :json
    assert_response :success
    record = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first

    post "/shop/api/phone_otp/verify_sms",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: @phone, code: record.code },
      as: :json
    assert_response :success, response.body
    assert_equal @phone, customer.reload.phone
    assert_equal email, customer.email
  end

  private

  def with_rack_attack
    was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear if Rack::Attack.cache.store.respond_to?(:clear)
    yield
  ensure
    Rack::Attack.cache.store.clear if Rack::Attack.cache.store.respond_to?(:clear)
    Rack::Attack.enabled = was_enabled
  end
end
