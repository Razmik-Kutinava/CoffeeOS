# frozen_string_literal: true

require "test_helper"

class Callbacks::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create_tenant!
    @user   = create_user!(tenant: @tenant, role_codes: %w[barista])

    @order = Order.create!(
      tenant:          @tenant,
      order_number:    "ORD-#{SecureRandom.hex(3)}",
      source:          "mobile",
      status:          "pending_payment",
      total_amount:    300,
      discount_amount: 0,
      final_amount:    300
    )

    @payment = Payment.create!(
      order:    @order,
      tenant:   @tenant,
      amount:   300,
      method:   "card",
      provider: "shop",
      status:   "pending"
    )

    Rails.cache.clear
  end

  teardown do
    ENV.delete("CALLBACK_SHARED_TOKEN")
    ENV.delete("CALLBACK_SHARED_SECRET")
    ENV.delete("CALLBACK_REQUIRE_IDEMPOTENCY")
    Rails.cache.clear
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def post_payment(params: {}, headers: {})
    default_params = {
      tenant_id:          @tenant.id,
      payment_id:         @payment.id,
      status:             "succeeded",
      provider_payment_id: "pay_#{SecureRandom.hex(4)}"
    }
    post "/callbacks/payments",
         params:  default_params.merge(params),
         headers: headers
  end

  def with_token(token = "test-token")
    ENV["CALLBACK_SHARED_TOKEN"] = token
    yield
  ensure
    ENV.delete("CALLBACK_SHARED_TOKEN")
  end

  def with_secret(secret = "test-secret")
    ENV["CALLBACK_SHARED_SECRET"] = secret
    yield
  ensure
    ENV.delete("CALLBACK_SHARED_SECRET")
  end

  def hmac_headers(secret:, body:, token: nil)
    timestamp = Time.current.to_i.to_s
    signed    = "#{timestamp}.#{body}"
    sig       = OpenSSL::HMAC.hexdigest("SHA256", secret, signed)
    headers   = {
      "X-Callback-Timestamp" => timestamp,
      "X-Callback-Signature" => sig,
      "X-Idempotency-Key"    => SecureRandom.hex(8)
    }
    headers["X-Callback-Token"] = token if token
    headers
  end

  def raw_body_for(params)
    params.to_query
  end

  # ---------------------------------------------------------------------------
  # Token authentication
  # ---------------------------------------------------------------------------

  test "wrong token returns 401" do
    with_token("correct-token") do
      post_payment(headers: { "X-Callback-Token" => "wrong-token" })
      assert_response :unauthorized
    end
  end

  test "missing token header when ENV set returns 401" do
    with_token("correct-token") do
      post_payment(headers: {})
      assert_response :unauthorized
    end
  end

  test "correct token passes authentication and returns 200" do
    with_token("correct-token") do
      post_payment(headers: { "X-Callback-Token" => "correct-token" })
      assert_response :ok
    end
  end

  test "when ENV token is blank, auth is skipped and request succeeds" do
    # ENV["CALLBACK_SHARED_TOKEN"] is not set — auth is bypassed in non-production
    post_payment(headers: {})
    assert_response :ok
  end

  # ---------------------------------------------------------------------------
  # HMAC authentication
  # ---------------------------------------------------------------------------

  test "invalid HMAC signature returns 401" do
    with_secret("my-secret") do
      # Also need a valid token so we get past the token check
      ENV["CALLBACK_SHARED_TOKEN"] = ""   # blank = skip token auth
      post_payment(
        headers: {
          "X-Callback-Timestamp" => Time.current.to_i.to_s,
          "X-Callback-Signature" => "badhex000000",
          "X-Idempotency-Key"    => SecureRandom.hex(8)
        }
      )
      assert_response :unauthorized
    end
  end

  test "missing signature headers when HMAC secret set returns 401" do
    with_secret("my-secret") do
      ENV["CALLBACK_SHARED_TOKEN"] = ""
      post_payment(
        headers: {
          "X-Idempotency-Key" => SecureRandom.hex(8)
          # No X-Callback-Timestamp / X-Callback-Signature
        }
      )
      assert_response :unauthorized
    end
  end

  # HMAC tests post JSON so raw_post == body.to_json (deterministic for signature computation)
  test "valid HMAC signature passes authentication" do
    secret = "my-secret"
    with_secret(secret) do
      ENV["CALLBACK_SHARED_TOKEN"] = ""

      req_params = {
        tenant_id:           @tenant.id,
        payment_id:          @payment.id,
        status:              "succeeded",
        provider_payment_id: "pay_hmac_ok"
      }

      body      = req_params.to_json
      timestamp = Time.current.to_i.to_s
      sig       = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{body}")

      post "/callbacks/payments",
           params:  body,
           headers: {
             "Content-Type"         => "application/json",
             "X-Callback-Timestamp" => timestamp,
             "X-Callback-Signature" => sig,
             "X-Idempotency-Key"    => SecureRandom.hex(8)
           }

      # Auth passed — not 401
      assert_not_equal 401, response.status
    end
  end

  # ---------------------------------------------------------------------------
  # Anti-replay — stale timestamp
  # ---------------------------------------------------------------------------

  test "stale timestamp older than 300 seconds returns 401" do
    secret = "my-secret"
    with_secret(secret) do
      ENV["CALLBACK_SHARED_TOKEN"] = ""

      req_params = { tenant_id: @tenant.id, payment_id: @payment.id, status: "succeeded" }
      body           = req_params.to_json
      stale_timestamp = (Time.current.to_i - 400).to_s
      sig             = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{stale_timestamp}.#{body}")

      post "/callbacks/payments",
           params:  body,
           headers: {
             "Content-Type"         => "application/json",
             "X-Callback-Timestamp" => stale_timestamp,
             "X-Callback-Signature" => sig,
             "X-Idempotency-Key"    => SecureRandom.hex(8)
           }

      assert_response :unauthorized
      assert_match(/stale/i, response.body)
    end
  end

  test "timestamp exactly within 300 seconds is accepted" do
    secret = "my-secret"
    with_secret(secret) do
      ENV["CALLBACK_SHARED_TOKEN"] = ""

      req_params = {
        tenant_id:           @tenant.id,
        payment_id:          @payment.id,
        status:              "succeeded",
        provider_payment_id: "pay_ts_ok"
      }

      body            = req_params.to_json
      fresh_timestamp = (Time.current.to_i - 299).to_s
      sig             = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{fresh_timestamp}.#{body}")

      post "/callbacks/payments",
           params:  body,
           headers: {
             "Content-Type"         => "application/json",
             "X-Callback-Timestamp" => fresh_timestamp,
             "X-Callback-Signature" => sig,
             "X-Idempotency-Key"    => SecureRandom.hex(8)
           }

      assert_not_equal 401, response.status
    end
  end

  # ---------------------------------------------------------------------------
  # Idempotency
  # ---------------------------------------------------------------------------

  test "duplicate idempotency key returns 200 with duplicate: true" do
    ENV["CALLBACK_REQUIRE_IDEMPOTENCY"] = "1"
    idem_key  = SecureRandom.hex(8)
    cache_key = "callbacks:idempotency:#{idem_key}"

    # Seed the cache to simulate a prior processed request
    Rails.cache.write(
      cache_key,
      { state: "processing", at: Time.current.to_i, action: "payment", payload_hash: "abc" },
      expires_in: 24.hours
    )

    post_payment(headers: { "X-Idempotency-Key" => idem_key })

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal true, body["duplicate"]
    assert_equal idem_key, body["idempotency_key"]
  end

  test "missing idempotency key when CALLBACK_REQUIRE_IDEMPOTENCY=1 returns 422" do
    ENV["CALLBACK_REQUIRE_IDEMPOTENCY"] = "1"
    post_payment(headers: {})   # no X-Idempotency-Key
    assert_response :unprocessable_entity
    assert_match(/idempotency/i, response.body)
  end

  test "unique idempotency key allows request to proceed" do
    ENV["CALLBACK_REQUIRE_IDEMPOTENCY"] = "1"
    idem_key = SecureRandom.hex(8)
    post_payment(headers: { "X-Idempotency-Key" => idem_key })
    # Should NOT be a duplicate response
    body = JSON.parse(response.body)
    assert_not body["duplicate"]
  end

  # ---------------------------------------------------------------------------
  # Payment status update
  # ---------------------------------------------------------------------------

  test "payment status is updated to succeeded" do
    post_payment(params: { status: "succeeded" }, headers: {})
    @payment.reload
    assert_equal "succeeded", @payment.status
  end

  test "payment provider_payment_id is stored" do
    provider_id = "ext_pay_#{SecureRandom.hex(4)}"
    post_payment(
      params:  { status: "succeeded", provider_payment_id: provider_id },
      headers: {}
    )
    @payment.reload
    assert_equal provider_id, @payment.provider_payment_id
  end

  test "payment paid_at is set when status becomes succeeded" do
    assert_nil @payment.paid_at
    post_payment(params: { status: "succeeded" }, headers: {})
    @payment.reload
    assert_not_nil @payment.paid_at
  end

  # ---------------------------------------------------------------------------
  # Order status transition on payment success
  # ---------------------------------------------------------------------------

  test "order status transitions to accepted when payment succeeds" do
    assert_equal "pending_payment", @order.status
    post_payment(params: { status: "succeeded" }, headers: {})
    @order.reload
    assert_equal "accepted", @order.status
  end

  test "order_status_log is created when order transitions to accepted" do
    log_count = OrderStatusLog.where(order: @order).count
    post_payment(params: { status: "succeeded" }, headers: {})
    assert_operator OrderStatusLog.where(order: @order).count, :>, log_count
  end

  test "already-accepted order is not double-transitioned" do
    @order.update!(status: "accepted")
    post_payment(params: { status: "succeeded" }, headers: {})
    @order.reload
    # Status stays accepted, not broken
    assert_equal "accepted", @order.status
  end

  # ---------------------------------------------------------------------------
  # Invalid status
  # ---------------------------------------------------------------------------

  test "invalid payment status returns 422" do
    post_payment(params: { status: "flying_saucer" }, headers: {})
    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "invalid payment status", body["error"]
  end

  # ---------------------------------------------------------------------------
  # Payment not found
  # ---------------------------------------------------------------------------

  test "non-existent payment_id returns 404" do
    post_payment(
      params:  { payment_id: 999_999_999, status: "succeeded" },
      headers: {}
    )
    assert_response :not_found
    body = JSON.parse(response.body)
    assert_equal "payment not found", body["error"]
  end

  test "payment belonging to different tenant returns 404" do
    other_tenant = create_tenant!
    post "/callbacks/payments",
         params: {
           tenant_id:  other_tenant.id,
           payment_id: @payment.id,
           status:     "succeeded"
         },
         headers: {}
    assert_response :not_found
  end

  # ---------------------------------------------------------------------------
  # Idempotency — payment NOT updated twice
  # ---------------------------------------------------------------------------

  test "second identical request with same idempotency key does not change payment status again" do
    ENV["CALLBACK_REQUIRE_IDEMPOTENCY"] = "1"
    idem_key = SecureRandom.hex(8)

    # First request — succeeds
    post_payment(
      params:  { status: "succeeded" },
      headers: { "X-Idempotency-Key" => idem_key }
    )
    @payment.reload
    first_updated_at = @payment.updated_at

    # Ensure cache key is populated (the first request writes it)
    # Simulate second request with same key
    post_payment(
      params:  { status: "succeeded" },
      headers: { "X-Idempotency-Key" => idem_key }
    )

    assert_response :ok
    body = JSON.parse(response.body)
    assert body["duplicate"], "Second request should be detected as duplicate"
    @payment.reload
    # Payment should not have been re-saved; updated_at must be unchanged
    assert_equal first_updated_at, @payment.updated_at
  end

  # ---------------------------------------------------------------------------
  # Successful response structure
  # ---------------------------------------------------------------------------

  test "successful response contains ok: true and payment_id" do
    post_payment(params: { status: "succeeded" }, headers: {})
    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal true,        body["ok"]
    assert_equal @payment.id, body["payment_id"]
    assert_equal "succeeded", body["status"]
  end
end
