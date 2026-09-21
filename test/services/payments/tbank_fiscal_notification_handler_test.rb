# frozen_string_literal: true

require "test_helper"

# #73 — inbound NotificationFiscalization (Status=RECEIPT)
class Payments::TbankFiscalNotificationHandlerTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
    disable_rls!

    @tenant = create_tenant!
    @order = Order.create!(
      tenant: @tenant,
      order_number: "ORD-FISCAL-#{SecureRandom.hex(3)}",
      source: "mobile",
      status: "accepted",
      total_amount: 500,
      discount_amount: 0,
      final_amount: 500
    )
    @payment = Payment.create!(
      order: @order,
      tenant: @tenant,
      amount: 500,
      method: "card",
      provider: "tbank",
      provider_payment_id: "pay_fiscal_#{SecureRandom.hex(4)}",
      status: "succeeded",
      provider_data: { "save_card" => false }
    )
  end

  teardown do
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
  end

  def disable_rls!
    conn = ActiveRecord::Base.connection
    %w[orders payments fiscal_receipts].each do |table|
      next unless conn.table_exists?(table)

      conn.execute("ALTER TABLE #{conn.quote_table_name(table)} DISABLE ROW LEVEL SECURITY")
    end
  end

  def fiscal_payload(overrides = {})
    {
      "TerminalKey" => "TestTerminal",
      "OrderId" => @order.id.to_s,
      "Success" => true,
      "Status" => "RECEIPT",
      "PaymentId" => @payment.provider_payment_id,
      "ErrorCode" => "0",
      "Amount" => 50000,
      "FnNumber" => "9999078900001234",
      "FiscalDocumentNumber" => 12345,
      "FiscalDocumentAttribute" => 987654321,
      "Type" => "Income",
      "Url" => "https://receipt.example/check/abc",
      "Ofd" => "platformaofd"
    }.merge(overrides)
  end

  test "[TDD] saves fiscal receipt from RECEIPT notification" do
    result = Payments::TbankFiscalNotificationHandler.new(payload: fiscal_payload).call!

    assert result[:ok]
    receipt = FiscalReceipt.find_by(payment_id: @payment.id)
    assert receipt, "FiscalReceipt must be created"
    assert_equal "tbank", receipt.ofd_provider
    assert_equal "payment", receipt.type
    assert_equal "confirmed", receipt.status
    assert_equal "https://receipt.example/check/abc", receipt.receipt_data["Url"]
    assert_equal "9999078900001234", receipt.receipt_data["FnNumber"]
    assert_equal 12345, receipt.receipt_data["FiscalDocumentNumber"].to_i
    assert_equal 987654321, receipt.receipt_data["FiscalDocumentAttribute"].to_i
    assert_equal "Income", receipt.receipt_data["Type"]
    assert receipt.receipt_data["raw"].is_a?(Hash)
    assert_equal "#{@payment.provider_payment_id}:9999078900001234:12345:987654321", receipt.ofd_receipt_id
  end

  test "[TDD] IncomeReturn creates separate refund receipt without replacing payment" do
    Payments::TbankFiscalNotificationHandler.new(payload: fiscal_payload).call!
    refund_payload = fiscal_payload(
      "Type" => "IncomeReturn",
      "FiscalDocumentNumber" => 12346,
      "FiscalDocumentAttribute" => 111,
      "Url" => "https://receipt.example/check/refund"
    )
    Payments::TbankFiscalNotificationHandler.new(payload: refund_payload).call!

    receipts = FiscalReceipt.where(payment_id: @payment.id).order(:created_at)
    assert_equal 2, receipts.count
    assert_equal "payment", receipts.first.type
    assert_equal "refund", receipts.second.type
    assert_equal "https://receipt.example/check/refund", receipts.second.receipt_data["Url"]
  end

  test "[TDD Patch1] second Income with unique ofd_receipt_id does not overwrite first" do
    Payments::TbankFiscalNotificationHandler.new(payload: fiscal_payload).call!
    second = fiscal_payload(
      "FiscalDocumentNumber" => 99901,
      "FiscalDocumentAttribute" => 99902,
      "Url" => "https://receipt.example/check/second"
    )
    Payments::TbankFiscalNotificationHandler.new(payload: second).call!

    receipts = FiscalReceipt.where(payment_id: @payment.id).order(:created_at)
    assert_equal 2, receipts.count
    assert_equal "payment", receipts.first.type
    assert_equal "payment", receipts.second.type
    assert_not_equal receipts.first.ofd_receipt_id, receipts.second.ofd_receipt_id
    assert_equal "https://receipt.example/check/abc", receipts.first.receipt_data["Url"]
    assert_equal "https://receipt.example/check/second", receipts.second.receipt_data["Url"]
  end

  test "[TDD Patch1] payment_not_found soft-skip does not enqueue retry after max attempt" do
    payload = fiscal_payload("PaymentId" => "missing-pay-id", "OrderId" => SecureRandom.uuid)

    assert_no_enqueued_jobs(only: Payments::TbankFiscalRetryJob) do
      result = Payments::TbankFiscalNotificationHandler.new(payload: payload, retry_attempt: 1).call!
      assert_equal :payment_not_found, result[:skipped]
    end
  end

  test "[TDD] retry is idempotent — one row" do
    payload = fiscal_payload
    Payments::TbankFiscalNotificationHandler.new(payload: payload).call!
    Payments::TbankFiscalNotificationHandler.new(payload: payload).call!

    assert_equal 1, FiscalReceipt.where(payment_id: @payment.id).count
  end

  test "[TDD] unknown PaymentId does not create receipt" do
    payload = fiscal_payload("PaymentId" => "missing-pay-id", "OrderId" => SecureRandom.uuid)
    result = Payments::TbankFiscalNotificationHandler.new(payload: payload).call!

    assert result[:ok]
    assert_equal 0, FiscalReceipt.where(ofd_receipt_id: "#{payload['PaymentId']}:9999078900001234:12345:987654321").count
  end

  # ---------------------------------------------------------------------------
  # TASK_93-F — F4 fiscal soft-skip → report / retry
  # ---------------------------------------------------------------------------

  def capture_error_reports
    reports = []
    original = Rails.error.method(:report)
    Rails.error.define_singleton_method(:report) do |error = nil, **kwargs, &block|
      reports << { error: error, **kwargs }
      nil
    end
    yield reports
  ensure
    Rails.error.define_singleton_method(:report) do |error = nil, **kwargs, &block|
      original.call(error, **kwargs, &block)
    end
  end

  # T-F4a
  test "T-F4a payment_not_found reports error" do
    payload = fiscal_payload("PaymentId" => "missing-pay-id", "OrderId" => SecureRandom.uuid)

    capture_error_reports do |reports|
      result = Payments::TbankFiscalNotificationHandler.new(payload: payload).call!
      assert result[:ok]
      assert_equal :payment_not_found, result[:skipped]
      assert_operator reports.size, :>=, 1, "payment_not_found must Rails.error.report"
    end
  end

  # T-F4b
  test "T-F4b missing_fiscal_ids reports error" do
    payload = fiscal_payload(
      "FnNumber" => nil,
      "FiscalDocumentNumber" => nil,
      "FiscalDocumentAttribute" => nil
    )

    capture_error_reports do |reports|
      result = Payments::TbankFiscalNotificationHandler.new(payload: payload).call!
      assert result[:ok]
      assert_equal :missing_fiscal_ids, result[:skipped]
      assert_operator reports.size, :>=, 1, "missing_fiscal_ids must Rails.error.report"
    end
  end

  # T-F4c
  test "T-F4c enqueues fiscal retry when payment_not_found" do
    payload = fiscal_payload("PaymentId" => "missing-pay-id", "OrderId" => SecureRandom.uuid)

    assert_enqueued_with(job: Payments::TbankFiscalRetryJob) do
      Payments::TbankFiscalNotificationHandler.new(payload: payload).call!
    end
  end

  # T-F4d
  test "[TDD] happy create receipt does not false-report" do
    capture_error_reports do |reports|
      result = Payments::TbankFiscalNotificationHandler.new(payload: fiscal_payload).call!
      assert result[:ok]
      assert result[:fiscal_receipt]
      assert_empty reports, "happy path must not Rails.error.report"
    end
  end

  test "[TDD] persist wraps FiscalReceipt create in Rls::JobTenantContext" do
    seen_tid = nil
    original = Rls::JobTenantContext.method(:with)
    Rls::JobTenantContext.define_singleton_method(:with) do |record, &block|
      seen_tid = record.tenant_id
      original.call(record, &block)
    end

    begin
      result = Payments::TbankFiscalNotificationHandler.new(payload: fiscal_payload).call!
      assert result[:ok]
      assert_equal @tenant.id, seen_tid
    ensure
      Rls::JobTenantContext.define_singleton_method(:with, original)
    end
  end
end
