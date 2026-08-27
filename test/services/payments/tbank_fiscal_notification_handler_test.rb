# frozen_string_literal: true

require "test_helper"

# #73 — inbound NotificationFiscalization (Status=RECEIPT)
class Payments::TbankFiscalNotificationHandlerTest < ActiveSupport::TestCase
  include TestFactories

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
end
