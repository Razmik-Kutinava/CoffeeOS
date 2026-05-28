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
end
