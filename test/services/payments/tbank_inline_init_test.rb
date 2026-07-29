# frozen_string_literal: true

require "test_helper"

# [TDD] Inline init: без RebillId → Init PayType O; с RebillId → Charge.
# ТЗ: Интеграция inline-оплаты Т-Банка · Шаг 1
class Payments::TbankInlineInitTest < ActiveSupport::TestCase
  setup do
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
  end

  teardown do
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
  end

  def order_stub(amount: "200.00")
    Struct.new(:id, :final_amount).new(SecureRandom.uuid, BigDecimal(amount))
  end

  def adapter_capturing(captured)
    adapter = Payments::TbankAdapter.new
    adapter.define_singleton_method(:post_json) do |url, payload|
      captured << { url: url, payload: payload }
      if url.end_with?("/Init")
        { "Success" => true, "PaymentURL" => "https://pay.tbank.ru/x", "PaymentId" => "pid-inline-1" }
      else
        { "Success" => true, "ErrorCode" => "0", "Status" => "CONFIRMED", "PaymentId" => "pid-inline-1" }
      end
    end
    adapter
  end

  test "[TDD] without rebill_id posts Init with PayType O and returns PaymentId" do
    order = order_stub
    captured = []
    adapter = adapter_capturing(captured)

    result = Payments::TbankInlineInit.call(
      order: order,
      adapter: adapter,
      return_base_url: "https://example.com",
      notification_url: "https://example.com/callbacks/tbank"
    )

    assert_equal 1, captured.size
    assert captured[0][:url].end_with?("/Init")
    assert_equal "O", captured[0][:payload]["PayType"]
    assert_equal "pid-inline-1", result[:provider_payment_id]
  end

  test "[TDD] with rebill_id posts Charge and returns PaymentId" do
    order = order_stub
    captured = []
    adapter = adapter_capturing(captured)

    result = Payments::TbankInlineInit.call(
      order: order,
      adapter: adapter,
      rebill_id: "rebill-42",
      return_base_url: "https://example.com",
      notification_url: "https://example.com/callbacks/tbank"
    )

    charge_call = captured.find { |c| c[:url].end_with?("/Charge") }
    assert charge_call, "ожидали POST /v2/Charge при RebillId"
    assert_equal "rebill-42", charge_call[:payload]["RebillId"]
    assert_equal "pid-inline-1", result[:provider_payment_id]
  end

  test "[TDD] Token is present and secrets stay off result contract" do
    order = order_stub
    captured = []
    adapter = adapter_capturing(captured)

    result = Payments::TbankInlineInit.call(
      order: order,
      adapter: adapter,
      return_base_url: "https://example.com",
      notification_url: "https://example.com/callbacks/tbank"
    )

    assert captured[0][:payload]["Token"].present?
    assert_nil captured[0][:payload]["Password"]
    assert_equal "pid-inline-1", result[:provider_payment_id]
    assert_nil result[:password]
    assert_nil result[:terminal_key]
  end
end
