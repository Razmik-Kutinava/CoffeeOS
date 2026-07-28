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

  test "send verify status happy path returns refresh_token" do
    post "/shop/api/phone_otp/send",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: "89009876543", channel: "sms" },
      as: :json
    assert_response :success, response.body
    assert_equal "+79009876543", response.parsed_body["phone"]

    record = MobileOtpCode.where(phone: "+79009876543", is_used: false).order(created_at: :desc).first
    assert record

    post "/shop/api/phone_otp/verify",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: "+79009876543", code: record.code },
      as: :json
    assert_response :success, response.body
    body = response.parsed_body
    assert_equal true, body["verified"]
    assert body["refresh_token"].present?
    assert MobileCustomer.exists?(phone: "+79009876543")

    get "/shop/api/phone_otp/status",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: "+79009876543" },
      as: :json
    assert_response :success
    assert_equal true, response.parsed_body["verified"]
  end

  test "send rejects invalid phone" do
    post "/shop/api/phone_otp/send",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: "123", channel: "sms" },
      as: :json
    assert_response :unprocessable_entity
  end

  test "send rejects invalid channel" do
    post "/shop/api/phone_otp/send",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: @phone, channel: "pigeon" },
      as: :json
    assert_response :unprocessable_entity
  end

  test "send messenger returns code and verify creates refresh_token" do
    post "/shop/api/phone_otp/send",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: @phone, channel: "messenger" },
      as: :json

    assert_response :success, response.body
    assert_equal @phone, response.parsed_body["phone"]

    record = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
    assert record
    assert_equal 4, record.code.length

    post "/shop/api/phone_otp/verify",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: @phone, code: record.code },
      as: :json

    assert_response :success, response.body
    body = response.parsed_body
    assert_equal true, body["verified"]
    assert body["refresh_token"].present?
    assert MobileCustomer.exists?(phone: @phone)
  end

  test "send messenger delivery error returns messenger_delivery_error flag" do
    original = Shop::MessengerClient.method(:deliver_otp!)
    Shop::MessengerClient.define_singleton_method(:deliver_otp!) do |to:, code:|
      raise Shop::MessengerClient::Error.new("Messenger delivery failed", http_status: 503)
    end

    begin
      post "/shop/api/phone_otp/send",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: @phone, channel: "messenger" },
        as: :json

      assert_response :bad_gateway
      assert_equal true, response.parsed_body["messenger_delivery_error"]
      assert_equal "messenger_delivery_error", response.parsed_body["error_code"]
    ensure
      Shop::MessengerClient.define_singleton_method(:deliver_otp!, original)
    end
  end

  test "links phone onto email-verified session customer" do
    email = "phone-api-link-#{SecureRandom.hex(3)}@example.com"
    verify_shop_email!(tenant_id: @tenant.id, email: email)
    customer = MobileCustomer.find_by!(email: email)

    post "/shop/api/phone_otp/send",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: @phone, channel: "sms" },
      as: :json
    assert_response :success
    record = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first

    post "/shop/api/phone_otp/verify",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: @phone, code: record.code },
      as: :json
    assert_response :success, response.body
    assert_equal @phone, customer.reload.phone
    assert_equal email, customer.email
  end
end
