# frozen_string_literal: true

require "test_helper"

class Payments::TbankAdapterRecurrentTest < ActiveSupport::TestCase
  setup do
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"]     = "TestPassword"
  end

  teardown do
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
    Payments::CacheCounter.clear_circuit!
  end

  test "init_payment sends Recurrent and CustomerKey when requested" do
    adapter = Payments::TbankAdapter.new
    captured = nil
    adapter.define_singleton_method(:post_json) do |url, payload|
      captured = { url: url, payload: payload }
      { "Success" => true, "PaymentURL" => "https://pay.example/", "PaymentId" => "111" }
    end

    order = Struct.new(:id, :final_amount).new(SecureRandom.uuid, BigDecimal("179"))
    adapter.init_payment(
      order: order,
      return_base_url: "https://shop.example",
      notification_url: "https://shop.example/callbacks/tbank",
      customer_key: "cust-1",
      recurrent: true
    )

    assert_equal "Y", captured[:payload]["Recurrent"]
    assert_equal "cust-1", captured[:payload]["CustomerKey"]
    assert captured[:payload]["Token"].present?
  end

  test "charge_recurrent calls Init then Charge with RebillId" do
    adapter = Payments::TbankAdapter.new
    calls = []
    adapter.define_singleton_method(:post_json) do |url, payload|
      calls << { url: url, payload: payload }
      if url.end_with?("/Init")
        { "Success" => true, "PaymentURL" => "https://pay.example/", "PaymentId" => "222" }
      else
        { "Success" => true, "Status" => "CONFIRMED" }
      end
    end

    order = Struct.new(:id, :final_amount).new(SecureRandom.uuid, BigDecimal("179"))
    result = adapter.charge_recurrent(
      order: order,
      rebill_id: "rebill-abc",
      return_base_url: "https://shop.example",
      notification_url: "https://shop.example/callbacks/tbank",
      customer_key: "cust-1"
    )

    assert_equal 2, calls.size
    assert calls[0][:url].end_with?("/Init")
    assert calls[1][:url].end_with?("/Charge")
    assert_equal "222", calls[1][:payload]["PaymentId"]
    assert_equal "rebill-abc", calls[1][:payload]["RebillId"]
    assert result[:charged]
    assert_equal "222", result[:provider_payment_id]
  end
end
