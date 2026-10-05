# frozen_string_literal: true

require "test_helper"

# #71 Патч_2: post-pay email → MobileCustomer.receipt_email (canonical prefill),
# MobileCustomer.email остаётся только подтверждённым → Receipt.Email/Phone как до Патч_1.
class Shop::Api::OrdersEmailPatch2Test < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper
  include ActiveJob::TestHelper

  setup do
    @tenant = create_tenant!
    @category = create_category!
    @product = create_product!(category: @category, name: "Капучино")
    clear_enqueued_jobs
  end

  def headers
    shop_tenant_headers(@tenant.id)
  end

  def random_phone
    "+7900#{rand(1_000_000..9_999_999)}"
  end

  def create_order!(customer)
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: customer.id,
      customer_name: "Guest",
      order_number: "202610-71P2-#{SecureRandom.hex(3)}",
      source: :mobile,
      status: :accepted,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    OrderItem.create!(
      order: order,
      product_id: @product.id,
      product_name: @product.name,
      quantity: 1,
      unit_price: 200,
      total_price: 200
    )
    order
  end

  def post_email!(order, email, sess: self, token: true)
    params = { email: email, marketing_consent: false }
    params[:reconnect_token] = Shop::GuestOrderReconnect.token_for(order) if token
    sess.post "/shop/api/orders/#{order.id}/email", headers: headers, params: params, as: :json
  end

  def bind_via_phone!(sess, phone)
    sess.post "/shop/api/phone_otp/send_sms", headers: headers, params: { phone: phone }, as: :json
    assert_equal 200, sess.response.status, sess.response.body
    normalized = Shop::PhoneNormalizer.normalize!(phone)
    code = MobileOtpCode.where(phone: normalized, is_used: false).order(created_at: :desc).first&.code
    assert code.present?, "ожидался OTP код для #{normalized}"
    sess.post "/shop/api/phone_otp/verify_sms", headers: headers, params: { phone: phone, code: code }, as: :json
    assert_equal 200, sess.response.status, sess.response.body
    MobileCustomer.find_by!(phone: normalized)
  end

  test "P2 S5 post-pay email goes to receipt_email, MobileCustomer.email untouched [TDD]" do
    customer = create_mobile_customer!(phone: random_phone)
    order = create_order!(customer)
    email = "p2-s5-#{SecureRandom.hex(3)}@example.com"

    post_email!(order, email)

    assert_response :success, response.body
    customer.reload
    assert_equal email, customer.receipt_email
    assert_nil customer.email
    assert_equal false, customer.email_verified
    assert customer.email_collected_at.present?
  end

  test "P2 S11/S12 receipt of next order keeps Phone when only post-pay email saved [TDD]" do
    customer = create_mobile_customer!(phone: random_phone)
    order1 = create_order!(customer)
    post_email!(order1, "p2-rcpt-#{SecureRandom.hex(3)}@example.com")
    assert_response :success, response.body

    order2 = create_order!(customer.reload)
    receipt = Payments::TbankReceiptBuilder.for_order!(order2.reload)

    assert_equal customer.phone, receipt["Phone"]
    assert_nil receipt["Email"]
  end

  test "P2 S11 post-pay email does not replace verified OTP email in receipt [TDD]" do
    verified = "p2-ver-#{SecureRandom.hex(3)}@example.com"
    customer = create_mobile_customer!(phone: random_phone, email: verified)
    customer.update!(email_verified: true)
    order1 = create_order!(customer)

    post_email!(order1, "p2-other-#{SecureRandom.hex(3)}@example.com")
    assert_response :success, response.body

    customer.reload
    assert_equal verified, customer.email
    assert_equal true, customer.email_verified
    receipt = Payments::TbankReceiptBuilder.for_order!(create_order!(customer).reload)
    assert_equal verified, receipt["Email"]
  end

  test "P2 S9 clearing post-pay email drops receipt_email, keeps verified email [TDD]" do
    verified = "p2-keep-#{SecureRandom.hex(3)}@example.com"
    customer = create_mobile_customer!(phone: random_phone, email: verified)
    customer.update!(email_verified: true, receipt_email: "p2-old-#{SecureRandom.hex(3)}@example.com")
    order = create_order!(customer)

    post_email!(order, "")

    assert_response :success, response.body
    customer.reload
    assert_nil customer.receipt_email
    assert_equal verified, customer.email
    assert_equal true, customer.email_verified
  end

  test "P2 S8 change email updates receipt_email [TDD]" do
    customer = create_mobile_customer!(phone: random_phone)
    customer.update!(receipt_email: "old@example.com")
    order = create_order!(customer)

    post_email!(order, "new@example.com")

    assert_response :success, response.body
    assert_equal "new@example.com", customer.reload.receipt_email
  end

  test "P2 S10 same email twice: no duplicate OrderEmail, contact or receipt job [TDD]" do
    customer = create_mobile_customer!(phone: random_phone)
    order = create_order!(customer)
    email = "p2-idem-#{SecureRandom.hex(3)}@example.com"

    post_email!(order, email)
    assert_response :success
    collected_at = customer.reload.email_collected_at
    clear_enqueued_jobs

    assert_no_enqueued_jobs(only: SendOrderReceiptEmailJob) do
      post_email!(order, email)
      assert_response :success
    end
    customer.reload
    assert_equal email, customer.receipt_email
    assert_equal collected_at.to_i, customer.email_collected_at.to_i
    assert_equal 1, OrderEmail.where(order_id: order.id, email: email).count
    assert_equal 1, MobileCustomer.where(receipt_email: email).count
  end

  test "P2 same receipt email on two customers is allowed (no identity claim) [TDD]" do
    shared = "p2-shared-#{SecureRandom.hex(3)}@example.com"
    a = create_mobile_customer!(phone: random_phone)
    a.update!(receipt_email: shared)
    b = create_mobile_customer!(phone: random_phone)

    post_email!(create_order!(b), shared)

    assert_response :success, response.body
    assert_equal shared, a.reload.receipt_email
    assert_equal shared, b.reload.receipt_email
  end

  test "P2 S4/S15 order #1 save → order #2 → profile API returns receipt_email [TDD]" do
    open_session do |sess|
      customer = bind_via_phone!(sess, random_phone)
      email = "p2-e2e-#{SecureRandom.hex(3)}@example.com"

      order1 = create_order!(customer)
      post_email!(order1, email, sess: sess, token: false)
      assert_equal 200, sess.response.status, sess.response.body

      OrderEmail.where(order_id: order1.id).delete_all
      create_order!(customer)

      sess.get "/shop/api/profile", headers: headers, as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal email, body["receipt_email"]
      assert_nil body["email"]
    end
  end

  test "P2 S6 user B saves own email — profile A unchanged [TDD]" do
    a = create_mobile_customer!(phone: random_phone)
    a.update!(receipt_email: "a-#{SecureRandom.hex(3)}@example.com")
    a_email = a.receipt_email

    open_session do |sess|
      b = bind_via_phone!(sess, random_phone)
      post_email!(create_order!(b), "b-#{SecureRandom.hex(3)}@example.com", sess: sess, token: false)
      assert_equal 200, sess.response.status, sess.response.body
      assert b.reload.receipt_email.present?
    end

    assert_equal a_email, a.reload.receipt_email
  end

  test "P2 S7 user B posts to order of user A — 404, profile A unchanged [TDD]" do
    a = create_mobile_customer!(phone: random_phone)
    a.update!(receipt_email: "a7-#{SecureRandom.hex(3)}@example.com")
    a_email = a.receipt_email
    order_a = create_order!(a)

    open_session do |sess|
      b = bind_via_phone!(sess, random_phone)
      post_email!(order_a, "evil-#{SecureRandom.hex(3)}@example.com", sess: sess, token: false)
      assert_equal 404, sess.response.status, sess.response.body
      assert_nil b.reload.receipt_email
    end

    assert_equal a_email, a.reload.receipt_email
    assert_equal 0, OrderEmail.where(order_id: order_a.id).count
  end
end
