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

  test "status does not auto-bind customer by phone without session link" do
    create_mobile_customer!(phone: @phone, email: "status-no-bind-#{SecureRandom.hex(3)}@example.com")

    get "/shop/api/phone_otp/status",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: @phone },
      as: :json
    assert_response :success
    body = response.parsed_body
    assert_equal false, body["verified"]
    assert_nil body["phone"]
    assert_nil Shop::CustomerSession.customer_id(session, @tenant.id)
  end

  test "status returns verified when session customer phone matches" do
    open_session do |sess|
      sess.post "/shop/api/phone_otp/send_sms",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: @phone },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body

      record = MobileOtpCode.where(phone: @phone, is_used: false).order(created_at: :desc).first
      sess.post "/shop/api/phone_otp/verify_sms",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: @phone, code: record.code },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body

      sess.get "/shop/api/phone_otp/status",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: @phone },
        as: :json
      assert_equal 200, sess.response.status
      body = sess.response.parsed_body
      assert_equal true, body["verified"]
      assert_equal @phone, body["phone"]
    end
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

  # Security: binding_step_up on the same verify that creates the lock must not unlock.
  test "verify_sms binding_step_up does not clear lock created by profile switch" do
    guest_email = "otp-lock-guest-#{SecureRandom.hex(3)}@example.com"
    donor_phone = "+79001112233"
    donor = create_mobile_customer!(phone: donor_phone, email: "otp-lock-donor-#{SecureRandom.hex(3)}@example.com")
    donor.update!(phone_verified: true, phone_status: :verified)
    MobilePaymentMethod.create!(
      customer_id: donor.id,
      payment_type: "card",
      card_token: "rebill-sec-#{SecureRandom.hex(4)}",
      card_masked: "4300****1111",
      card_brand: "MIR",
      is_active: true,
      is_default: true
    )

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: guest_email, session: sess)
      guest_id = Shop::CustomerSession.customer_id(sess.session, @tenant.id)
      assert guest_id.present?
      refute_equal donor.id.to_s, guest_id.to_s

      sess.post "/shop/api/phone_otp/send_sms",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: donor_phone },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      record = MobileOtpCode.where(phone: donor_phone, is_used: false).order(created_at: :desc).first

      sess.post "/shop/api/phone_otp/verify_sms",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: donor_phone, code: record.code, binding_step_up: true },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body

      assert_equal donor.id.to_s, Shop::CustomerSession.customer_id(sess.session, @tenant.id).to_s
      assert Payments::BindingStepUp.payments_locked?(sess.session, @tenant.id),
        "lock from profile switch must survive same-request binding_step_up"
    end
  end

  test "verify_sms binding_step_up unlocks only when lock existed before link" do
    phone = "+79004445566"
    customer = create_mobile_customer!(phone: phone, email: "otp-unlock-#{SecureRandom.hex(3)}@example.com")
    customer.update!(phone_verified: true, phone_status: :verified)

    open_session do |sess|
      sess.get "/shop/api/config",
        headers: shop_tenant_headers(@tenant.id),
        as: :json
      assert_equal 200, sess.response.status, sess.response.body

      Shop::CustomerSession.set_customer_id!(sess.session, @tenant.id, customer.id)
      Payments::BindingStepUp.lock_payments!(sess.session, @tenant.id)
      assert Payments::BindingStepUp.payments_locked?(sess.session, @tenant.id)

      sess.post "/shop/api/phone_otp/send_sms",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: phone },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      record = MobileOtpCode.where(phone: phone, is_used: false).order(created_at: :desc).first

      sess.post "/shop/api/phone_otp/verify_sms",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: phone, code: record.code, binding_step_up: true },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      refute Payments::BindingStepUp.payments_locked?(sess.session, @tenant.id)
    end
  end

end
