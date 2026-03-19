require "test_helper"
require "openssl"

class CallbacksE2ETest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.clear
    path = Rails.root.join("tmp", "callback_idempotency_keys.log")
    File.delete(path) if File.exist?(path)
  end

  def post_signed_callback(path, payload:, secret:, idempotency_key:)
    body = payload.to_json
    timestamp = Time.current.to_i.to_s
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{body}")

    post path,
      params: body,
      headers: {
        "CONTENT_TYPE" => "application/json",
        "X-Callback-Timestamp" => timestamp,
        "X-Callback-Signature" => signature,
        "X-Idempotency-Key" => idempotency_key
      }
  end

  def create_order!(tenant:, cash_shift:, status: "accepted", source: "manual", amount: 100)
    Order.create!(
      tenant: tenant,
      cash_shift: cash_shift,
      order_number: "ORD-#{SecureRandom.hex(4)}",
      source: source,
      status: status,
      total_amount: amount,
      discount_amount: 0,
      final_amount: amount
    )
  end

  def create_payment!(tenant:, order:, amount:, status: "pending", method: "cash", provider: "acq")
    Payment.create!(
      tenant: tenant,
      order: order,
      amount: amount,
      method: method,
      provider: provider,
      status: status,
      paid_at: status == "succeeded" ? Time.current : nil
    )
  end

  def create_fiscal_receipt!(tenant:, order:, payment:, type: "payment", status: "pending")
    FiscalReceipt.create!(
      tenant: tenant,
      order: order,
      payment: payment,
      type: type,
      status: status,
      ofd_provider: "ofd-test",
      receipt_data: { "items" => [] }
    )
  end

  test "payment and fiscal callbacks update statuses and manager views" do
    previous_secret = ENV["CALLBACK_SHARED_SECRET"]
    ENV["CALLBACK_SHARED_SECRET"] = "test-callback-secret"

    tenant = create_tenant!(name: "TCB", slug: "tcb")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "cb-bar@test.com", name: "CbBar")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "cb-office@test.com", name: "CbOffice")

    shift = open_cash_shift!(tenant: tenant, opened_by: barista)
    order = create_order!(tenant: tenant, cash_shift: shift, status: "accepted", amount: 150)
    payment = create_payment!(tenant: tenant, order: order, amount: 150, status: "pending")
    receipt = create_fiscal_receipt!(tenant: tenant, order: order, payment: payment, status: "pending")

    login_as!(office)
    get "/manager/incidents"
    assert_response :success
    assert_includes response.body, payment.status
    assert_not_includes response.body, "failed"

    # payment callback -> succeeded (pending payment should leave incidents)
    post_signed_callback(
      "/callbacks/payments",
      payload: {
        tenant_id: tenant.id,
        payment_id: payment.id,
        status: "succeeded",
        provider_payment_id: "pay-cb-1",
        provider_data: { "gateway" => "acq" },
        note: "callback ok"
      },
      secret: ENV["CALLBACK_SHARED_SECRET"],
      idempotency_key: "idem-pay-1"
    )
    assert_response :success
    assert_equal "succeeded", payment.reload.status
    assert_equal "pay-cb-1", payment.provider_payment_id
    assert PaymentStatusLog.where(payment_id: payment.id, source: "callback", status_to: "succeeded").exists?

    get "/manager/incidents"
    assert_response :success
    assert_not_includes response.body, "pending"

    # fiscal callback -> failed (must appear as blocker)
    post_signed_callback(
      "/callbacks/fiscal_receipts",
      payload: {
        tenant_id: tenant.id,
        fiscal_receipt_id: receipt.id,
        status: "failed",
        error_message: "ofd timeout",
        provider_data: { "attempt" => 1 }
      },
      secret: ENV["CALLBACK_SHARED_SECRET"],
      idempotency_key: "idem-fisc-1"
    )
    assert_response :success
    assert_equal "failed", receipt.reload.status
    assert_equal "ofd timeout", receipt.error_message

    get "/manager/incidents"
    assert_response :success
    assert_includes response.body, order.order_number
    assert_includes response.body, "failed"

    # close wizard must block because of failed receipt
    post "/manager/shifts/#{shift.id}/close", params: { closing_cash: 100 }
    assert_response :redirect
    follow_redirect!
    assert_includes response.body, "Нельзя закрыть смену"
    assert_equal "open", shift.reload.status

    # fiscal callback -> confirmed, blocker gone
    post_signed_callback(
      "/callbacks/fiscal_receipts",
      payload: {
        tenant_id: tenant.id,
        fiscal_receipt_id: receipt.id,
        status: "confirmed",
        ofd_receipt_id: "ofd-777"
      },
      secret: ENV["CALLBACK_SHARED_SECRET"],
      idempotency_key: "idem-fisc-2"
    )
    assert_response :success
    assert_equal "confirmed", receipt.reload.status
    assert_equal "ofd-777", receipt.ofd_receipt_id

    post "/manager/shifts/#{shift.id}/close", params: { closing_cash: 100 }
    assert_response :redirect
    assert_equal "closed", shift.reload.status
  ensure
    ENV["CALLBACK_SHARED_SECRET"] = previous_secret
  end

  test "payment callback idempotency prevents double-processing" do
    previous_secret = ENV["CALLBACK_SHARED_SECRET"]
    ENV["CALLBACK_SHARED_SECRET"] = "test-callback-secret"

    tenant = create_tenant!(name: "TCB2", slug: "tcb2")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "cb2-bar@test.com", name: "Cb2Bar")
    shift = open_cash_shift!(tenant: tenant, opened_by: barista)
    order = create_order!(tenant: tenant, cash_shift: shift, status: "accepted", amount: 120)
    payment = create_payment!(tenant: tenant, order: order, amount: 120, status: "pending")

    payload = {
      tenant_id: tenant.id,
      payment_id: payment.id,
      status: "succeeded",
      provider_payment_id: "pay-idem-1",
      provider_data: { "gateway" => "acq" },
      note: "callback idem"
    }

    post_signed_callback(
      "/callbacks/payments",
      payload: payload,
      secret: ENV["CALLBACK_SHARED_SECRET"],
      idempotency_key: "idem-dup-1"
    )
    assert_response :success

    logs_after_first = PaymentStatusLog.where(payment_id: payment.id, source: "callback", status_to: "succeeded").count
    assert_equal 1, logs_after_first

    post_signed_callback(
      "/callbacks/payments",
      payload: payload,
      secret: ENV["CALLBACK_SHARED_SECRET"],
      idempotency_key: "idem-dup-1"
    )
    assert_response :success
    assert_includes response.body, "duplicate"

    logs_after_second = PaymentStatusLog.where(payment_id: payment.id, source: "callback", status_to: "succeeded").count
    assert_equal 1, logs_after_second
  ensure
    ENV["CALLBACK_SHARED_SECRET"] = previous_secret
  end
end

