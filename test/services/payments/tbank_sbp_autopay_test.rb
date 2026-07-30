# frozen_string_literal: true

require "test_helper"

# RED [TDD] #34 Шаг 1–3: HTTP-методы Т-Кассы GetAddAccountQRState / ChargeQr.
# Канон: Payments::TbankSbpAutopay (не раздувать tbank_adapter.rb).
class Payments::TbankSbpAutopayTest < ActiveSupport::TestCase
  setup do
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
  end

  teardown do
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
  end

  test "TbankSbpAutopay class is defined" do
    assert defined?(Payments::TbankSbpAutopay),
      "[TDD] ожидается Payments::TbankSbpAutopay для GetAddAccountQRState / ChargeQr"
  end

  test "get_add_account_qr_state posts RequestKey and returns AccountToken" do
    captured = nil
    client = Object.new
    client.define_singleton_method(:post) do |path, body|
      captured = { path: path, body: body }
      {
        "Success" => true,
        "ErrorCode" => "0",
        "AccountToken" => "acct-token-sbp-001",
        "Status" => "ACTIVE"
      }
    end

    result = Payments::TbankSbpAutopay.new(http: client).get_add_account_qr_state(request_key: "rk-abc-1")

    assert_equal "acct-token-sbp-001", result[:account_token]
    assert_match(%r{GetAddAccountQRState}i, captured[:path].to_s)
    assert_equal "rk-abc-1", captured[:body]["RequestKey"]
    assert captured[:body]["Token"].present?, "Token SHA-256 обязателен на бэкенде"
    assert_equal "TestTerminal", captured[:body]["TerminalKey"]
  end

  test "charge_qr posts PaymentId + AccountToken" do
    captured = nil
    client = Object.new
    client.define_singleton_method(:post) do |path, body|
      captured = { path: path, body: body }
      {
        "Success" => true,
        "ErrorCode" => "0",
        "Status" => "CONFIRMED",
        "PaymentId" => "pay-99"
      }
    end

    result = Payments::TbankSbpAutopay.new(http: client).charge_qr(
      payment_id: "pay-99",
      account_token: "acct-token-sbp-001"
    )

    assert_equal "CONFIRMED", result[:status]
    assert_match(%r{ChargeQr}i, captured[:path].to_s)
    assert_equal "pay-99", captured[:body]["PaymentId"]
    assert_equal "acct-token-sbp-001", captured[:body]["AccountToken"]
    assert captured[:body]["Token"].present?
  end

  test "charge_qr maps bank decline to CHARGE_DECLINED (soft by default)" do
    client = Object.new
    client.define_singleton_method(:post) do |_path, _body|
      {
        "Success" => false,
        "ErrorCode" => "1051",
        "Message" => "Недостаточно средств",
        "Status" => "REJECTED"
      }
    end

    error = assert_raises(Payments::TbankSbpAutopay::ChargeDeclined) do
      Payments::TbankSbpAutopay.new(http: client).charge_qr(
        payment_id: "pay-1",
        account_token: "acct-1"
      )
    end

    assert_equal "CHARGE_DECLINED", error.error_code
    assert_equal false, error.fatal?, "недостаточно средств — soft, токен не удалять"
  end

  test "charge_qr marks closed account as fatal decline" do
    client = Object.new
    client.define_singleton_method(:post) do |_path, _body|
      {
        "Success" => false,
        "ErrorCode" => "9999",
        "Message" => "Счет закрыт",
        "Status" => "REJECTED"
      }
    end

    error = assert_raises(Payments::TbankSbpAutopay::ChargeDeclined) do
      Payments::TbankSbpAutopay.new(http: client).charge_qr(
        payment_id: "pay-2",
        account_token: "acct-closed"
      )
    end

    assert_equal "CHARGE_DECLINED", error.error_code
    assert_equal true, error.fatal?
  end
end
