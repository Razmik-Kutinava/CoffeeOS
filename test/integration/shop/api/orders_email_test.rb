# frozen_string_literal: true

require "test_helper"

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
      customer_id: nil,
      customer_name: "Guest",
      order_number: "202608-71-#{SecureRandom.hex(2)}",
      source: :mobile,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    clear_enqueued_jobs
  end

  test "S8 saves email without OTP and returns success" do
    assert_enqueued_with(job: SendOrderReceiptEmailJob) do
      post "/shop/api/orders/#{@order.id}/email",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: "guest-#{SecureRandom.hex(3)}@example.com", marketing_consent: false },
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
      params: { email: "invalid@", marketing_consent: false },
      as: :json

    assert_response :bad_request
    assert_equal 0, OrderEmail.where(order_id: @order.id).count
  end

  test "S8 allows empty email without creating OrderEmail row" do
    post "/shop/api/orders/#{@order.id}/email",
      headers: shop_tenant_headers(@tenant.id),
      params: { email: "", marketing_consent: false },
      as: :json

    assert_response :success, response.body
    assert_equal true, response.parsed_body["success"]
    assert_equal 0, OrderEmail.where(order_id: @order.id).count
  end

  test "S9 enqueues CRM only when marketing_consent true" do
    email = "crm-#{SecureRandom.hex(3)}@example.com"

    assert_no_enqueued_jobs(only: SyncContactToCrmJob) do
      post "/shop/api/orders/#{@order.id}/email",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: email, marketing_consent: false },
        as: :json
      assert_response :success
    end

    clear_enqueued_jobs
    other = "crm2-#{SecureRandom.hex(3)}@example.com"
    assert_enqueued_with(job: SyncContactToCrmJob) do
      post "/shop/api/orders/#{@order.id}/email",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: other, marketing_consent: true },
        as: :json
      assert_response :success
    end
  end

  test "S14 idempotent second POST same email" do
    email = "idem-#{SecureRandom.hex(3)}@example.com"

    post "/shop/api/orders/#{@order.id}/email",
      headers: shop_tenant_headers(@tenant.id),
      params: { email: email, marketing_consent: false },
      as: :json
    assert_response :success

    clear_enqueued_jobs
    assert_no_enqueued_jobs(only: SendOrderReceiptEmailJob) do
      post "/shop/api/orders/#{@order.id}/email",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: email, marketing_consent: false },
        as: :json
      assert_response :success
    end
    assert_equal 1, OrderEmail.where(order_id: @order.id, email: email).count
  end

  test "S11 bounce marks order_email bounced" do
    oe = OrderEmail.create!(
      order: @order,
      email: "bounce-#{SecureRandom.hex(3)}@example.com",
      marketing_consent: false,
      status: :pending
    )

    post "/callbacks/email/bounce",
      params: { email: oe.email, reason: "mailbox_full" },
      as: :json

    assert_response :success
    assert_equal "bounced", oe.reload.status
    assert_equal "mailbox_full", oe.bounce_reason
  end
end
