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
    # Как у заказчика: вход в OTP — flash_call; sms сам код не генерирует (cascade).
    post "/shop/api/phone_otp/send",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: "89009876543", channel: "flash_call" },
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

  test "rack attack throttles flash_call by 20 seconds" do
    with_rack_attack do
      post "/shop/api/phone_otp/send",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: @phone, channel: "flash_call" },
        as: :json
      assert_response :success

      post "/shop/api/phone_otp/send",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: @phone, channel: "flash_call" },
        as: :json
      assert_response :too_many_requests
    end
  end

  test "rack attack throttles sms by 60 seconds" do
    with_rack_attack do
      # Как у заказчика: sms сам код не генерирует — сначала flash_call (создаёт активный код).
      post "/shop/api/phone_otp/send",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: @phone, channel: "flash_call" },
        as: :json
      assert_response :success

      post "/shop/api/phone_otp/send",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: @phone, channel: "sms" },
        as: :json
      assert_response :success

      post "/shop/api/phone_otp/send",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: @phone, channel: "sms" },
        as: :json
      assert_response :too_many_requests
    end
  end

  test "links phone onto email-verified session customer" do
    email = "phone-api-link-#{SecureRandom.hex(3)}@example.com"
    verify_shop_email!(tenant_id: @tenant.id, email: email)
    customer = MobileCustomer.find_by!(email: email)

    # Как у заказчика: вход в OTP — flash_call; sms сам код не генерирует (cascade).
    post "/shop/api/phone_otp/send",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: @phone, channel: "flash_call" },
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
