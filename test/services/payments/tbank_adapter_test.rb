# frozen_string_literal: true

require "test_helper"

class Payments::TbankAdapterTest < ActiveSupport::TestCase
  setup do
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"]     = "TestPassword"
  end

  teardown do
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
  end

  # ---------------------------------------------------------------------------
  # build_token
  # ---------------------------------------------------------------------------

  test "build_token produces correct SHA256 of sorted values + password" do
    adapter = Payments::TbankAdapter.new
    params = {
      "TerminalKey" => "TestTerminal",
      "Amount"      => 10000,
      "OrderId"     => "42"
    }
    # Sorted by key: Amount, OrderId, Password, TerminalKey
    # Values concatenated: 1000042TestPasswordTestTerminal
    expected = Digest::SHA256.hexdigest("1000042TestPasswordTestTerminal")
    assert_equal expected, adapter.build_token(params)
  end

  test "build_token ignores Token key" do
    adapter = Payments::TbankAdapter.new
    params_without = { "TerminalKey" => "TestTerminal" }
    params_with    = { "TerminalKey" => "TestTerminal", "Token" => "should_be_ignored" }
    assert_equal adapter.build_token(params_without), adapter.build_token(params_with)
  end

  # ---------------------------------------------------------------------------
  # verify_notification
  # ---------------------------------------------------------------------------

  test "verify_notification returns true for valid token" do
    adapter = Payments::TbankAdapter.new
    payload = {
      "TerminalKey" => "TestTerminal",
      "OrderId"     => "99",
      "Status"      => "CONFIRMED",
      "PaymentId"   => "456"
    }
    payload["Token"] = adapter.build_token(payload)
    assert Payments::TbankAdapter.verify_notification(payload)
  end

  test "verify_notification returns false for tampered token" do
    payload = {
      "TerminalKey" => "TestTerminal",
      "OrderId"     => "99",
      "Status"      => "CONFIRMED",
      "Token"       => "badhash"
    }
    assert_not Payments::TbankAdapter.verify_notification(payload)
  end

  test "verify_notification returns false when Token is missing" do
    assert_not Payments::TbankAdapter.verify_notification({ "OrderId" => "1" })
  end

  # ---------------------------------------------------------------------------
  # map_status
  # ---------------------------------------------------------------------------

  test "map_status CONFIRMED → succeeded" do
    assert_equal "succeeded", Payments::TbankAdapter.map_status("CONFIRMED")
  end

  test "map_status AUTHORIZED → processing" do
    assert_equal "processing", Payments::TbankAdapter.map_status("AUTHORIZED")
  end

  test "map_status REJECTED → failed" do
    assert_equal "failed", Payments::TbankAdapter.map_status("REJECTED")
  end

  test "map_status CANCELED → failed" do
    assert_equal "failed", Payments::TbankAdapter.map_status("CANCELED")
  end

  test "map_status REFUNDED → refunded" do
    assert_equal "refunded", Payments::TbankAdapter.map_status("REFUNDED")
  end

  test "map_status PARTIAL_REFUNDED → partially_refunded" do
    assert_equal "partially_refunded", Payments::TbankAdapter.map_status("PARTIAL_REFUNDED")
  end

  test "map_status unknown → nil" do
    assert_nil Payments::TbankAdapter.map_status("UNKNOWN_STATUS")
  end

  test "map_status FORM_SHOWED → nil (ignored status)" do
    assert_nil Payments::TbankAdapter.map_status("FORM_SHOWED")
  end

  # ---------------------------------------------------------------------------
  # ENV guard
  # ---------------------------------------------------------------------------

  test "raises Error when TBANK_TERMINAL_KEY is not set" do
    ENV.delete("TBANK_TERMINAL_KEY")
    order = Struct.new(:id, :final_amount).new(1, BigDecimal("100.00"))
    assert_raises(Payments::TbankAdapter::Error) do
      Payments::TbankAdapter.new.init_payment(
        order: order,
        return_base_url: "https://example.com",
        notification_url: "https://example.com/callbacks/tbank"
      )
    end
  end

  test "ApiError from T-Bank does not trip circuit breaker" do
    adapter = Payments::TbankAdapter.new
    order = Struct.new(:id, :final_amount).new(SecureRandom.uuid, BigDecimal("100.00"))

    adapter.define_singleton_method(:post_json) do |*_args|
      { "Success" => false, "ErrorCode" => "9999", "Message" => "bad" }
    end

    assert_raises(Payments::TbankAdapter::ApiError) do
      adapter.init_payment(
        order: order,
        return_base_url: "https://example.com",
        notification_url: "https://example.com/callbacks/tbank"
      )
    end

    assert_not Payments::CacheCounter.present?(Payments::TbankAdapter::CB_OPEN_KEY)
    assert_equal 0, Payments::CacheCounter.read(Payments::TbankAdapter::CB_FAILURES_KEY)
  ensure
    Payments::CacheCounter.clear_circuit!
  end

  test "transport errors increment circuit failures" do
    adapter = Payments::TbankAdapter.new
    order = Struct.new(:id, :final_amount).new(SecureRandom.uuid, BigDecimal("100.00"))

    adapter.define_singleton_method(:post_json) do |*_args|
      raise Payments::TbankAdapter::Error, "timeout"
    end

    assert_raises(Payments::TbankAdapter::Error) do
      adapter.init_payment(
        order: order,
        return_base_url: "https://example.com",
        notification_url: "https://example.com/callbacks/tbank"
      )
    end

    assert_equal 1, Payments::CacheCounter.read(Payments::TbankAdapter::CB_FAILURES_KEY)
  ensure
    Payments::CacheCounter.clear_circuit!
  end

  test "socket errors are wrapped as Error" do
    adapter = Payments::TbankAdapter.new
    order = Struct.new(:id, :final_amount).new(SecureRandom.uuid, BigDecimal("100.00"))

    adapter.define_singleton_method(:post_json) do |*_args|
      raise SocketError, "connection refused"
    end

    error = assert_raises(Payments::TbankAdapter::Error) do
      adapter.init_payment(
        order: order,
        return_base_url: "https://example.com",
        notification_url: "https://example.com/callbacks/tbank"
      )
    end
    assert_match(/connection refused/i, error.message)
  ensure
    Payments::CacheCounter.clear_circuit!
  end

  test "finish_authorize posts CardData to FinishAuthorize endpoint" do
    adapter = Payments::TbankAdapter.new
    captured = nil
    adapter.define_singleton_method(:post_json) do |url, payload|
      captured = { url: url, payload: payload }
      { "Success" => true, "ErrorCode" => "0", "Status" => "CONFIRMED", "PaymentId" => "fa-1" }
    end

    response = adapter.finish_authorize(payment_id: "fa-1", card_data: "base64-encrypted")
    assert captured[:url].end_with?("/FinishAuthorize")
    assert_equal "base64-encrypted", captured[:payload]["CardData"]
    assert_equal "CONFIRMED", response["Status"]
  end

  test "charge posts RebillId to Charge endpoint" do
    adapter = Payments::TbankAdapter.new
    captured = nil
    adapter.define_singleton_method(:post_json) do |url, payload|
      captured = { url: url, payload: payload }
      { "Success" => true, "ErrorCode" => "0", "Status" => "CONFIRMED" }
    end

    adapter.charge(payment_id: "pay-9", rebill_id: "rebill-9")
    assert captured[:url].end_with?("/Charge")
    assert_equal "rebill-9", captured[:payload]["RebillId"]
  end

  test "get_payment_state returns bank response on success" do
    adapter = Payments::TbankAdapter.new
    adapter.define_singleton_method(:post_json) do |_url, _payload|
      {
        "Success" => true,
        "ErrorCode" => "0",
        "Status" => "CONFIRMED",
        "PaymentId" => "pay-42"
      }
    end

    response = adapter.get_payment_state(payment_id: "pay-42")
    assert_equal "CONFIRMED", response["Status"]
  end
end
