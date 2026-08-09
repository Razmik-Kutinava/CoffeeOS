# frozen_string_literal: true

require "test_helper"

class Shop::Api::ProfileMergeTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!(slug: "prof-merge-#{SecureRandom.hex(3)}")
    @phone = "+7900#{rand(1000000..9999999)}"
    @email = "prof-#{SecureRandom.hex(3)}@example.com"
    ENV["SHOP_OTP_LOG_FALLBACK"] = "true"
  end

  test "GET profile returns contract fields when authenticated" do
    customer = MobileCustomer.create!(
      phone: @phone,
      email: @email,
      first_name: "Иван",
      last_name: "Петров",
      is_active: true,
      email_verified: true,
      phone_verified: true
    )

    open_session do |sess|
      bind_via_phone!(sess, customer.phone)
      sess.get "/shop/api/profile", headers: shop_tenant_headers(@tenant.id), as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal customer.id, body["id"]
      assert_equal @email, body["email"]
      assert_equal true, body["email_verified"]
      assert_equal @phone, body["phone"]
      assert_equal true, body["phone_verified"]
      assert_equal "Иван", body["first_name"]
      assert_equal "Петров", body["last_name"]
    end
  end

  test "GET profile returns 401 without customer session" do
    get "/shop/api/profile", headers: shop_tenant_headers(@tenant.id), as: :json
    assert_equal 401, response.status
  end

  test "PATCH profile updates names" do
    customer = MobileCustomer.create!(
      phone: @phone,
      first_name: "Old",
      last_name: "Name",
      is_active: true,
      phone_verified: true
    )

    open_session do |sess|
      bind_via_phone!(sess, customer.phone)
      sess.patch "/shop/api/profile",
        headers: shop_tenant_headers(@tenant.id),
        params: { first_name: "Новое", last_name: "Имя" },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal "Новое", body["first_name"]
      assert_equal "Имя", body["last_name"]
      customer.reload
      assert_equal "Новое", customer.first_name
      assert_equal "Имя", customer.last_name
    end
  end

  test "PATCH profile 422 on blank first_name" do
    customer = MobileCustomer.create!(
      phone: @phone,
      first_name: "Old",
      is_active: true,
      phone_verified: true
    )

    open_session do |sess|
      bind_via_phone!(sess, customer.phone)
      sess.patch "/shop/api/profile",
        headers: shop_tenant_headers(@tenant.id),
        params: { first_name: "" },
        as: :json
      assert_equal 422, sess.response.status
    end
  end

  test "POST link_email clean attach after OTP code" do
    customer = MobileCustomer.create!(
      phone: @phone,
      first_name: "Phone",
      is_active: true,
      phone_verified: true
    )

    open_session do |sess|
      bind_via_phone!(sess, customer.phone)
      clear_email_otp_cooldown!(@email)
      sess.post "/shop/api/email_otp/send",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: @email },
        as: :json
      assert_equal 200, sess.response.status

      sess.post "/shop/api/profile/link_email",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: @email, code: "123456" },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal @email, body["email"]
      assert_equal true, body["email_verified"]
      assert_equal @email, customer.reload.email
      assert customer.email_verified
    end
  end

  test "POST link_email merges duplicate email customer" do
    survivor = MobileCustomer.create!(
      phone: @phone,
      first_name: "Phone",
      is_active: true,
      phone_verified: true
    )
    donor = MobileCustomer.create!(
      email: @email,
      first_name: "Mail",
      is_active: true,
      email_verified: true
    )
    order = Order.create!(
      tenant: @tenant,
      customer_id: donor.id,
      order_number: "LNK-#{SecureRandom.hex(3)}",
      source: :mobile,
      status: :accepted,
      total_amount: 50,
      discount_amount: 0,
      final_amount: 50
    )

    open_session do |sess|
      bind_via_phone!(sess, survivor.phone)
      clear_email_otp_cooldown!(@email)
      sess.post "/shop/api/email_otp/send",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: @email },
        as: :json
      assert_equal 200, sess.response.status

      sess.post "/shop/api/profile/link_email",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: @email, code: "123456" },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      assert_equal survivor.id, order.reload.customer_id
      assert_equal false, donor.reload.is_active
      assert_equal @email, survivor.reload.email
      assert survivor.email_verified
    end
  end

  test "POST link_phone clean attach after phone OTP code" do
    customer = MobileCustomer.create!(
      email: @email,
      first_name: "Mail",
      is_active: true,
      email_verified: true
    )
    other_phone = "+7901#{rand(1000000..9999999)}"

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/phone_otp/send",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: other_phone, channel: "flash_call" },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      code = latest_phone_otp_code(other_phone)

      sess.post "/shop/api/profile/link_phone",
        headers: shop_tenant_headers(@tenant.id),
        params: { phone: other_phone, code: code },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal other_phone, body["phone"]
      assert_equal true, body["phone_verified"]
      assert_equal other_phone, customer.reload.phone
    end
  end

  private

  def bind_via_phone!(sess, phone)
    # Как у заказчика: реальный вход в OTP — flash_call (виджет PhoneAuthWizard),
    # sms сам код не генерирует — только повторяет уже существующий (cascade).
    sess.post "/shop/api/phone_otp/send",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: phone, channel: "flash_call" },
      as: :json
    assert_equal 200, sess.response.status, sess.response.body
    code = latest_phone_otp_code(phone)

    sess.post "/shop/api/phone_otp/verify",
      headers: shop_tenant_headers(@tenant.id),
      params: { phone: phone, code: code },
      as: :json
    assert_equal 200, sess.response.status, sess.response.body
  end

  def latest_phone_otp_code(phone)
    normalized = Shop::PhoneNormalizer.normalize!(phone)
    code = MobileOtpCode.where(phone: normalized, is_used: false).order(created_at: :desc).first&.code
    assert code.present?, "ожидался OTP код для #{normalized}"
    code
  end
end
