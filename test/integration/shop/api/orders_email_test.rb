# frozen_string_literal: true

require "test_helper"
require "openssl"

# #71 Email-сбор после оплаты — POST /shop/api/orders/:id/email (без OTP)
class Shop::Api::OrdersEmailTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper
  include ActiveJob::TestHelper

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(phone: "+7900#{rand(10_000_000..99_999_999)}")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "202608-71-#{SecureRandom.hex(2)}",
      source: :mobile,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    @reconnect = Shop::GuestOrderReconnect.token_for(@order)
    @bounce_secret = "test-bounce-secret-#{SecureRandom.hex(4)}"
    ENV["EMAIL_BOUNCE_WEBHOOK_SECRET"] = @bounce_secret
    clear_enqueued_jobs
  end

  teardown do
    ENV.delete("EMAIL_BOUNCE_WEBHOOK_SECRET")
  end

  def email_params(extra = {})
    { reconnect_token: @reconnect, marketing_consent: false }.merge(extra)
  end

  def bounce_headers(body)
    sig = OpenSSL::HMAC.hexdigest("SHA256", @bounce_secret, body)
    { "X-Webhook-Signature" => sig }
  end

  test "S8 saves email without OTP and returns success" do
    assert_enqueued_with(job: SendOrderReceiptEmailJob) do
      post "/shop/api/orders/#{@order.id}/email",
        headers: shop_tenant_headers(@tenant.id),
        params: email_params(email: "guest-#{SecureRandom.hex(3)}@example.com"),
        as: :json
    end

    assert_response :success, response.body
    json = response.parsed_body
    assert_equal true, json["success"]
    assert json["email"].present?
    assert_equal true, json["queued_receipt"]
    assert_equal 1, OrderEmail.where(order_id: @order.id, email: json["email"]).count
  end

  test "S8 rejects invalid email with 400" do
    post "/shop/api/orders/#{@order.id}/email",
      headers: shop_tenant_headers(@tenant.id),
      params: email_params(email: "invalid@"),
      as: :json

    assert_response :bad_request
    assert_equal 0, OrderEmail.where(order_id: @order.id).count
  end

  test "S8 allows empty email without creating OrderEmail row" do
    post "/shop/api/orders/#{@order.id}/email",
      headers: shop_tenant_headers(@tenant.id),
      params: email_params(email: ""),
      as: :json

    assert_response :success, response.body
    assert_equal true, response.parsed_body["success"]
    assert_equal 0, OrderEmail.where(order_id: @order.id).count
  end

  test "S8 rejects email on foreign order without session or token" do
    post "/shop/api/orders/#{@order.id}/email",
      headers: shop_tenant_headers(@tenant.id),
      params: { email: "nope@example.com", marketing_consent: false },
      as: :json

    assert_response :not_found
    assert_equal 0, OrderEmail.where(order_id: @order.id).count
  end

  test "S9 enqueues CRM only when marketing_consent true" do
    email = "crm-#{SecureRandom.hex(3)}@example.com"

    assert_no_enqueued_jobs(only: SyncContactToCrmJob) do
      post "/shop/api/orders/#{@order.id}/email",
        headers: shop_tenant_headers(@tenant.id),
        params: email_params(email: email, marketing_consent: false),
        as: :json
      assert_response :success
    end

    clear_enqueued_jobs
    other = "crm2-#{SecureRandom.hex(3)}@example.com"
    assert_enqueued_with(job: SyncContactToCrmJob) do
      post "/shop/api/orders/#{@order.id}/email",
        headers: shop_tenant_headers(@tenant.id),
        params: email_params(email: other, marketing_consent: true),
        as: :json
      assert_response :success
    end
  end

  test "S14 idempotent second POST same email" do
    email = "idem-#{SecureRandom.hex(3)}@example.com"

    post "/shop/api/orders/#{@order.id}/email",
      headers: shop_tenant_headers(@tenant.id),
      params: email_params(email: email),
      as: :json
    assert_response :success

    clear_enqueued_jobs
    assert_no_enqueued_jobs(only: SendOrderReceiptEmailJob) do
      post "/shop/api/orders/#{@order.id}/email",
        headers: shop_tenant_headers(@tenant.id),
        params: email_params(email: email),
        as: :json
      assert_response :success
    end
    assert_equal 1, OrderEmail.where(order_id: @order.id, email: email).count
  end

  test "S11 bounce marks order_email bounced with HMAC" do
    oe = OrderEmail.create!(
      order: @order,
      email: "bounce-#{SecureRandom.hex(3)}@example.com",
      marketing_consent: false,
      status: :pending
    )

    payload = { email: oe.email, reason: "mailbox_full", order_id: @order.id }
    body = payload.to_json
    post "/callbacks/email/bounce",
      params: payload,
      headers: bounce_headers(body),
      as: :json

    assert_response :success, response.body
    assert_equal "bounced", oe.reload.status
    assert_equal "mailbox_full", oe.bounce_reason
  end

  test "S11 bounce without signature is unauthorized" do
    post "/callbacks/email/bounce",
      params: { email: "x@example.com", reason: "x" },
      as: :json

    assert_response :unauthorized
  end
end
