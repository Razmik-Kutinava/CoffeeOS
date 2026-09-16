# frozen_string_literal: true

require "test_helper"

class Payments::TbankCallbackJobTest < ActiveJob::TestCase
  include TestFactories

  setup do
    disable_rls_on_orders_payments!
    @tenant = create_tenant!
    @order = Order.create!(
      tenant: @tenant,
      order_number: "ORD-#{SecureRandom.hex(3)}",
      source: "mobile",
      status: "pending_payment",
      total_amount: 500,
      discount_amount: 0,
      final_amount: 500
    )
    @provider_payment_id = "pay_#{SecureRandom.hex(4)}"
    @payment = Payment.create!(
      order: @order,
      tenant: @tenant,
      amount: 500,
      method: "card",
      provider: "tbank",
      provider_payment_id: @provider_payment_id,
      status: "pending"
    )
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
  end

  teardown do
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
  end

  def build_payload(amount_kopecks: 50_000, status: "CONFIRMED")
    p = {
      "TerminalKey" => "TestTerminal",
      "OrderId" => @order.id.to_s,
      "PaymentId" => @provider_payment_id,
      "Status" => status,
      "Amount" => amount_kopecks
    }
    p["Token"] = Payments::TbankAdapter.new.build_token(p)
    p
  end

  test "CONFIRMED with matching Amount marks payment succeeded" do
    Payments::TbankCallbackJob.perform_now(build_payload)
    assert_equal "succeeded", @payment.reload.status
  end

  test "CONFIRMED with Amount mismatch does not mark payment succeeded" do
    Payments::TbankCallbackJob.perform_now(build_payload(amount_kopecks: 100))
    assert_equal "pending", @payment.reload.status
  end

  def disable_rls_on_orders_payments!
    conn = ActiveRecord::Base.connection
    %w[orders payments].each do |table|
      next unless conn.table_exists?(table)

      conn.execute("ALTER TABLE #{conn.quote_table_name(table)} DISABLE ROW LEVEL SECURITY")
    end
  end
end
