# frozen_string_literal: true

require "test_helper"

# IB Phase 1 — IDOR: shop API order ownership across customers / guest sessions.
class Shop::Api::OwnershipIdorTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)
    @customer_a = create_mobile_customer!(email: "owner-a-#{SecureRandom.hex(4)}@example.com")
    @email_a = @customer_a.email
    @customer_b = create_mobile_customer!(email: "owner-b-#{SecureRandom.hex(4)}@example.com")
    @email_b = @customer_b.email
    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
  end

  teardown do
    Current.reset
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
  end

  def headers
    shop_tenant_headers(@tenant.id)
  end

  def create_order_for!(session, email:, name: "Guest")
    session.post "/shop/api/cart/add",
      headers: headers,
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_equal 200, session.response.status, session.response.body

    verify_shop_email!(tenant_id: @tenant.id, email: email, session: session)

    session.post "/shop/api/orders",
      headers: headers,
      params: shop_order_params(email: email, name: name, payment_method: "card"),
      as: :json
    assert_equal 200, session.response.status, session.response.body
    session.response.parsed_body["order_id"]
  end

  def build_pending_order!(customer:)
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: customer.id,
      customer_name: "Pending",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    OrderItem.create!(
      order_id: order.id,
      product_id: @product.id,
      product_name: "Латте",
      quantity: 1,
      unit_price: 200,
      total_price: 200
    )
    Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: 200,
      method: :sbp,
      provider: "tbank",
      status: :pending
    )
    order
  end

  test "customer B cannot GET order show for customer A order" do
    order_id = nil
    open_session do |sess_a|
      order_id = create_order_for!(sess_a, email: @email_a, name: "A")
    end

    open_session do |sess_b|
      verify_shop_email!(tenant_id: @tenant.id, email: @email_b, session: sess_b)
      sess_b.get "/shop/api/orders/#{order_id}", headers: headers
      assert_includes [ 401, 404 ], sess_b.response.status
    end
  end

  test "customer B cannot GET payments status for customer A order" do
    order = build_pending_order!(customer: @customer_a)

    open_session do |sess_b|
      verify_shop_email!(tenant_id: @tenant.id, email: @email_b, session: sess_b)
      sess_b.get "/shop/api/payments/status/#{order.id}", headers: headers, as: :json
      assert_equal 404, sess_b.response.status, sess_b.response.body
    end
  end

  test "customer B cannot POST widget_init for customer A order" do
    order = build_pending_order!(customer: @customer_a)

    open_session do |sess_b|
      verify_shop_email!(tenant_id: @tenant.id, email: @email_b, session: sess_b)
      sess_b.post "/shop/api/payments/widget_init",
        headers: headers,
        params: { order_id: order.id },
        as: :json
      assert_equal 404, sess_b.response.status, sess_b.response.body
    end
  end

  test "customer B cannot POST sbp init for customer A pending order" do
    order = build_pending_order!(customer: @customer_a)

    open_session do |sess_b|
      verify_shop_email!(tenant_id: @tenant.id, email: @email_b, session: sess_b)
      sess_b.post "/shop/api/payments/sbp/init",
        headers: headers,
        params: { order_id: order.id },
        as: :json
      assert_equal 404, sess_b.response.status, sess_b.response.body
    end
  end

  test "customer A can GET show and payments status for own order" do
    order = build_pending_order!(customer: @customer_a)

    open_session do |sess_a|
      verify_shop_email!(tenant_id: @tenant.id, email: @email_a, session: sess_a)
      sess_a.get "/shop/api/orders/#{order.id}", headers: headers
      assert_equal 200, sess_a.response.status, sess_a.response.body

      sess_a.get "/shop/api/payments/status/#{order.id}", headers: headers, as: :json
      assert_equal 200, sess_a.response.status, sess_a.response.body
      assert_equal "PENDING", sess_a.response.parsed_body["status"]
    end
  end

  test "guest with pending order in session can GET status without customer_id" do
    old_sim = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    guest_email = "guest-pending-#{SecureRandom.hex(4)}@example.com"

    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      verify_shop_email!(tenant_id: @tenant.id, email: guest_email, session: sess)

      sess.post "/shop/api/orders",
        headers: headers,
        params: shop_order_params(
          email: guest_email,
          name: "Guest Pending",
          payment_method: "sbp",
          defer_payment_init: true
        ),
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      order_id = sess.response.parsed_body["order_id"]
      assert_equal "pending_payment", sess.response.parsed_body["status"]

      Shop::CustomerSession.clear!(sess.session, @tenant.id)

      sess.get "/shop/api/payments/status/#{order_id}", headers: headers, as: :json
      assert_equal 200, sess.response.status, sess.response.body
      assert_equal "PENDING", sess.response.parsed_body["status"]
    end
  ensure
    ENV["SHOP_SIMULATE_PAYMENT"] = old_sim
  end

  test "valid reconnect_token allows show invalid token returns 404" do
    order_id = nil
    token = nil
    open_session do |sess|
      order_id = create_order_for!(sess, email: @email_a, name: "Reconnect")
      token = sess.response.parsed_body["reconnect_token"]
    end

    open_session do |lost|
      lost.get "/shop/api/orders/#{order_id}",
        headers: headers,
        params: { reconnect_token: "invalid-token" }
      assert_includes [ 401, 404 ], lost.response.status

      lost.get "/shop/api/orders/#{order_id}",
        headers: headers,
        params: { reconnect_token: token }
      assert_equal 200, lost.response.status, lost.response.body
      assert_equal order_id, lost.response.parsed_body["id"]
    end
  end

  test "profile requires customer session user_cards empty without customer" do
    get "/shop/api/profile", headers: headers, as: :json
    assert_response :unauthorized

    get "/shop/api/user/cards", headers: headers, as: :json
    assert_response :success
    assert_equal [], response.parsed_body["cards"]
    assert_nil response.parsed_body["primary"]
  end

  test "user_cards ignores unverified email param without session customer" do
    MobilePaymentMethod.create!(
      customer_id: @customer_a.id,
      payment_type: "card",
      card_masked: "220220******5953",
      card_expires_at: "09/27",
      card_token: "rebill-idor-#{SecureRandom.hex(4)}",
      is_active: true,
      is_default: true
    )

    get "/shop/api/user/cards",
      headers: headers,
      params: { email: @email_a },
      as: :json
    assert_response :success
    assert_equal [], response.parsed_body["cards"]
  end

  test "DELETE session does not deactivate another customers refresh_token" do
    refresh_token_a = nil
    open_session do |sess_a|
      verify_shop_email!(tenant_id: @tenant.id, email: @email_a, session: sess_a)
      refresh_token_a = sess_a.response.parsed_body["refresh_token"]
      assert refresh_token_a.present?
    end

    open_session do |sess_b|
      verify_shop_email!(tenant_id: @tenant.id, email: @email_b, session: sess_b)
      sess_b.delete "/shop/api/session",
        headers: headers,
        params: { refresh_token: refresh_token_a },
        as: :json
      assert_equal 200, sess_b.response.status
    end

    ms = MobileSession.find_by(refresh_token: refresh_token_a)
    assert ms
    assert_equal true, ms.is_active, "logout B must not revoke A refresh token"
  end

  test "profile is scoped to session customer after OTP" do
    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @email_a, session: sess)
      sess.get "/shop/api/profile", headers: headers, as: :json
      assert_equal 200, sess.response.status
      assert_equal @customer_a.id.to_s, sess.response.parsed_body["id"].to_s
    end
  end
end
