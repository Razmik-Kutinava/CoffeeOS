# frozen_string_literal: true

require "test_helper"

# Шаги 2–3: refresh_token на OTP verify + Silent Refresh API.
class Shop::Api::SessionRefreshTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "sref-#{SecureRandom.hex(3)}")
    Rails.cache.clear
  end

  test "email_otp verify returns refresh_token and creates MobileSession" do
    email = "sref-v-#{SecureRandom.hex(3)}@example.com"

    open_session do |sess|
      sess.post "/shop/api/email_otp/send",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: email },
        as: :json
      assert_equal 200, sess.response.status

      sess.post "/shop/api/email_otp/verify",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: email, code: "123456" },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert body["refresh_token"].present?, "verify должен вернуть refresh_token"
      assert_match(/\A[0-9a-f]{64}\z/, body["refresh_token"])

      ms = MobileSession.find_by(refresh_token: body["refresh_token"])
      assert ms, "MobileSession должна быть создана"
      assert ms.is_active
      assert ms.expires_at > 89.days.from_now
    end
  end

  test "refresh restores customer session and rotates token" do
    email = "sref-ok-#{SecureRandom.hex(3)}@example.com"
    old_token = nil

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: email, session: sess)
      old_token = sess.response.parsed_body["refresh_token"]
      assert old_token.present?
    end

    open_session do |sess|
      sess.post "/shop/api/session/refresh",
        headers: shop_tenant_headers(@tenant.id),
        params: { refresh_token: old_token },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      new_token = body["refresh_token"]
      assert new_token.present?
      refute_equal old_token, new_token

      assert body["profile"].is_a?(Hash)
      assert body["profile"]["id"].present?, "refresh должен вернуть профиль с id"

      cid = Shop::CustomerSession.customer_id(sess.request.session, @tenant.id)
      assert cid.present?

      assert_equal false, MobileSession.find_by!(refresh_token: old_token).is_active
      fresh = MobileSession.find_by!(refresh_token: new_token)
      assert fresh.is_active
      assert fresh.expires_at > 89.days.from_now
    end
  end

  test "refresh with expired token returns 401" do
    customer = create_mobile_customer!(email: "sref-exp-#{SecureRandom.hex(3)}@example.com")
    token = SecureRandom.hex(32)
    MobileSession.create!(
      customer_id: customer.id,
      refresh_token: token,
      is_active: true,
      expires_at: 1.second.ago
    )

    post "/shop/api/session/refresh",
      headers: shop_tenant_headers(@tenant.id),
      params: { refresh_token: token },
      as: :json
    assert_equal 401, response.status
  end

  test "refresh with inactive token returns 401" do
    customer = create_mobile_customer!(email: "sref-ina-#{SecureRandom.hex(3)}@example.com")
    token = SecureRandom.hex(32)
    MobileSession.create!(
      customer_id: customer.id,
      refresh_token: token,
      is_active: false,
      expires_at: 90.days.from_now
    )

    post "/shop/api/session/refresh",
      headers: shop_tenant_headers(@tenant.id),
      params: { refresh_token: token },
      as: :json
    assert_equal 401, response.status
  end

  test "old token after rotation returns 401" do
    email = "sref-rot-#{SecureRandom.hex(3)}@example.com"
    old_token = nil

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: email, session: sess)
      old_token = sess.response.parsed_body["refresh_token"]
    end

    open_session do |sess|
      sess.post "/shop/api/session/refresh",
        headers: shop_tenant_headers(@tenant.id),
        params: { refresh_token: old_token },
        as: :json
      assert_equal 200, sess.response.status
    end

    post "/shop/api/session/refresh",
      headers: shop_tenant_headers(@tenant.id),
      params: { refresh_token: old_token },
      as: :json
    assert_equal 401, response.status
  end

  test "refresh extends shop_email_verifications" do
    email = "sref-ttl-#{SecureRandom.hex(3)}@example.com"
    token = nil

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: email, session: sess)
      token = sess.response.parsed_body["refresh_token"]
      rec = ShopEmailVerification.find_by!(tenant_id: @tenant.id, email: email.downcase)
      rec.update!(expires_at: 1.hour.from_now)
    end

    open_session do |sess|
      sess.post "/shop/api/session/refresh",
        headers: shop_tenant_headers(@tenant.id),
        params: { refresh_token: token },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      rec = ShopEmailVerification.find_by!(tenant_id: @tenant.id, email: email.downcase)
      assert rec.expires_at > 89.days.from_now
    end
  end
end
