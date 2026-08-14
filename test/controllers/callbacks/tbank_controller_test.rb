# frozen_string_literal: true

require "test_helper"

class Callbacks::TbankControllerTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ActiveJob::TestHelper

  module FakePollingConfirm
    mattr_accessor :enabled, default: false

    module Override
      def get_payment_state(payment_id:)
        return super unless FakePollingConfirm.enabled

        {
          "Success" => true,
          "ErrorCode" => "0",
          "Status" => "AUTHORIZED",
          "PaymentId" => payment_id.to_s
        }
      end

      def confirm_payment(payment_id:)
        return super unless FakePollingConfirm.enabled

        {
          "Success" => true,
          "ErrorCode" => "0",
          "Status" => "CONFIRMED",
          "PaymentId" => payment_id.to_s
        }
      end
    end

    def self.install!
      return if @prepended

      Payments::TbankAdapter.prepend(Override)
      @prepended = true
    end
  end

  # Симулирует полный провал perform_now + enqueue → 500 (для release claim).
  module FakeJobTotalFail
    mattr_accessor :enabled, default: false

    module Override
      def perform_now(*)
        raise StandardError, "simulated perform_now failure" if FakeJobTotalFail.enabled

        super
      end

      def perform_later(*)
        raise SolidQueue::Job::EnqueueError, "simulated enqueue failure" if FakeJobTotalFail.enabled

        super
      end
    end

    def self.install!
      return if @prepended

      Payments::TbankCallbackJob.singleton_class.prepend(Override)
      @prepended = true
    end
  end

  setup do
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"]     = "TestPassword"
    # не ходить в GetState (5×1с) и не открывать circuit соседнему worker
    ENV["TBANK_REBILL_SYNC_RETRIES"] = "1"
    ENV["TBANK_REBILL_SYNC_PAUSE_SEC"] = "0"

    disable_rls_on_orders_payments!
    clear_enqueued_jobs
    clear_performed_jobs
    Payments::CacheCounter.clear!

    @tenant = create_tenant!
    FakePollingConfirm.install!
    FakePollingConfirm.enabled = false
    FakeJobTotalFail.install!
    FakeJobTotalFail.enabled = false

    @order = Order.create!(
      tenant:          @tenant,
      order_number:    "ORD-#{SecureRandom.hex(3)}",
      source:          "mobile",
      status:          "pending_payment",
      total_amount:    500,
      discount_amount: 0,
      final_amount:    500
    )

    @provider_payment_id = "tbank_pay_#{SecureRandom.hex(6)}"

    @payment = Payment.create!(
      order:               @order,
      tenant:              @tenant,
      amount:              500,
      method:              "card",
      provider:            "tbank",
      provider_payment_id: @provider_payment_id,
      status:              "pending",
      # иначе CONFIRMED без RebillId → live GetState → retry_on enqueue (CI flake)
      provider_data:       { "save_card" => false }
    )
  end

  teardown do
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
    ENV.delete("TBANK_REBILL_SYNC_RETRIES")
    ENV.delete("TBANK_REBILL_SYNC_PAUSE_SEC")
    FakeJobTotalFail.enabled = false
    Payments::CacheCounter.clear!
    Rails.cache.clear
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def tbank_payload(status: "CONFIRMED", payment_id: nil, order_id: nil)
    pid = payment_id || @provider_payment_id
    p = {
      "TerminalKey" => "TestTerminal",
      "OrderId"     => (order_id || @order.id).to_s,
      "PaymentId"   => pid,
      "Status"      => status,
      "Amount"      => 50000
    }
    p["Token"] = Payments::TbankAdapter.new.build_token(p)
    p
  end

  def post_notify(payload)
    post "/callbacks/tbank",
      params: payload.to_json,
      headers: { "Content-Type" => "application/json" }
  end

  # Parallel CI: соседний worker может ENABLE RLS на shared DB; @@rls_disabled в test_helper — один раз.
  def disable_rls_on_orders_payments!
    conn = ActiveRecord::Base.connection
    %w[orders payments].each do |table|
      next unless conn.table_exists?(table)

      conn.execute("ALTER TABLE #{conn.quote_table_name(table)} DISABLE ROW LEVEL SECURITY")
    end
  end

  # ---------------------------------------------------------------------------
  # Auth
  # ---------------------------------------------------------------------------

  test "returns 401 for invalid token" do
    payload = tbank_payload
    payload["Token"] = "badhash"
    post_notify(payload)
    assert_response :unauthorized
  end

  test "returns 400 for empty body" do
    post "/callbacks/tbank", params: "", headers: { "Content-Type" => "application/json" }
    assert_response :bad_request
  end

  # ---------------------------------------------------------------------------
  # CONFIRMED → job enqueued → order accepted
  # ---------------------------------------------------------------------------

  test "CONFIRMED performs TbankCallbackJob inline (worker optional)" do
    # class-level stub: не оставлять enabled после соседних тестов в том же worker
    FakeJobTotalFail.enabled = false
    clear_enqueued_jobs
    post_notify(tbank_payload(status: "CONFIRMED"))
    assert_response :ok
    leftover = enqueued_jobs.count { |job| job[:job] == Payments::TbankCallbackJob }
    assert_equal 0, leftover, "perform_now must not leave TbankCallbackJob in queue (retry_on/fallback)"
    assert_equal "succeeded", @payment.reload.status
    assert_equal "accepted", @order.reload.status
  end

  test "CONFIRMED transitions order to accepted and payment to succeeded after job" do
    post_notify(tbank_payload(status: "CONFIRMED"))
    assert_equal "succeeded", @payment.reload.status
    assert_equal "accepted",  @order.reload.status
  end

  test "CONFIRMED broadcasts synchronously (no BroadcastOrderBoardJob)" do
    assert_no_enqueued_jobs(only: Barista::BroadcastOrderBoardJob) do
      post_notify(tbank_payload(status: "CONFIRMED"))
    end
    assert_equal "accepted", @order.reload.status
  end

  test "CONFIRMED stores provider_payment_id after job" do
    post_notify(tbank_payload(status: "CONFIRMED"))
    assert_equal @provider_payment_id, @payment.reload.provider_payment_id
  end

  test "CONFIRMED response body contains ok: true" do
    post_notify(tbank_payload(status: "CONFIRMED"))
    assert_equal true, JSON.parse(response.body)["ok"]
  end

  # ---------------------------------------------------------------------------
  # REJECTED → job enqueued → payment failed
  # ---------------------------------------------------------------------------

  test "REJECTED transitions payment to failed after job" do
    post_notify(tbank_payload(status: "REJECTED"))
    assert_response :ok
    assert_equal "failed",   @payment.reload.status
    assert_equal "cancelled", @order.reload.status
  end

  # ---------------------------------------------------------------------------
  # Idempotency — дубль игнорируется
  # ---------------------------------------------------------------------------

  test "duplicate webhook returns ok with duplicate: true" do
    post_notify(tbank_payload(status: "CONFIRMED"))
    assert_response :ok

    post_notify(tbank_payload(status: "CONFIRMED"))
    assert_response :ok
    assert_equal true, JSON.parse(response.body)["duplicate"]
  end

  test "idempotency claim is stored in Rails.cache (shared across workers) [TDD]" do
    idem_key = "tbank:callback:#{@provider_payment_id}:CONFIRMED"
    post_notify(tbank_payload(status: "CONFIRMED"))
    assert_response :ok

    assert Rails.cache.exist?(idem_key), "claim must live in Rails.cache (Solid Cache on Fly)"
    assert_not Payments::CacheCounter.present?(idem_key), "must not use process-local CacheCounter for webhook dedup"
  end

  test "releases Rails.cache claim when job and enqueue both fail so bank retry can reprocess" do
    idem_key = "tbank:callback:#{@provider_payment_id}:CONFIRMED"
    FakeJobTotalFail.enabled = true
    begin
      post_notify(tbank_payload(status: "CONFIRMED"))
      assert_response :internal_server_error
      assert_not Rails.cache.exist?(idem_key), "claim must be released on 500"
      assert_equal "pending", @payment.reload.status
    ensure
      FakeJobTotalFail.enabled = false
    end

    post_notify(tbank_payload(status: "CONFIRMED"))
    assert_response :ok
    assert_nil JSON.parse(response.body)["duplicate"]
    assert_equal "succeeded", @payment.reload.status
    assert_equal "accepted", @order.reload.status
  end

  test "duplicate path does not delete another request claim [TDD]" do
    idem_key = "tbank:callback:#{@provider_payment_id}:CONFIRMED"
    assert Rails.cache.write(idem_key, 1, expires_in: 1.hour, unless_exist: true)

    post_notify(tbank_payload(status: "CONFIRMED"))
    assert_response :ok
    assert_equal true, JSON.parse(response.body)["duplicate"]
    assert Rails.cache.exist?(idem_key), "duplicate handler must not release foreign/in-flight claim"
    assert_equal "pending", @payment.reload.status
  end

  test "rejects oversized webhook body with 413 [TDD]" do
    huge_body = "x" * (256_000 + 1)
    post "/callbacks/tbank",
      params: huge_body,
      headers: { "Content-Type" => "application/json" }

    assert_response :content_too_large
    assert_equal "too large", JSON.parse(response.body)["error"]
    assert_equal "pending", @payment.reload.status
  end

  # ---------------------------------------------------------------------------
  # Ignored statuses
  # ---------------------------------------------------------------------------

  test "FORM_SHOWED returns ok without enqueuing job" do
    assert_no_enqueued_jobs do
      post_notify(tbank_payload(status: "FORM_SHOWED"))
    end
    assert_response :ok
    assert_equal "pending", @payment.reload.status
  end

  # ---------------------------------------------------------------------------
  # Step 3 RED: race webhook vs polling
  # ---------------------------------------------------------------------------

  test "race: webhook AUTHORIZED after polling-confirm should not downgrade succeeded payment [TDD]" do
    # 1) Polling (GET /payments/status) доводит payment до succeeded via GetState(AUTHORIZED) → Confirm
    FakePollingConfirm.enabled = true
    @payment.update!(status: :processing)

    get(
      "/shop/api/payments/status/#{@order.id}",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      as: :json
    )

    assert_response :success
    assert_equal "CONFIRMED", JSON.parse(response.body)["status"]
    assert_equal "succeeded", @payment.reload.status

    FakePollingConfirm.enabled = false

    # 2) Затем приходит устаревший webhook AUTHORIZED — не должны “даунгрейдить” final status
    post_notify(tbank_payload(status: "AUTHORIZED"))
    assert_response :ok

    assert_equal "succeeded", @payment.reload.status
  end

  # ---------------------------------------------------------------------------
  # Payment not found — job logs warning, no error
  # ---------------------------------------------------------------------------

  test "unknown order runs job inline and returns ok" do
    assert_no_enqueued_jobs(only: Payments::TbankCallbackJob) do
      post_notify(tbank_payload(order_id: 999999, payment_id: "no_such_id"))
    end
    assert_response :ok
  end
end
