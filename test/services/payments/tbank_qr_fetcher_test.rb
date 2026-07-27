# frozen_string_literal: true

require "test_helper"

# RED [TDD] Шаг 2: GetQr PAYMENT_LINK → deep link qr.nspk.ru.
# Реализации ещё нет — ожидаем падение (NameError / assert).
class Payments::TbankQrFetcherTest < ActiveSupport::TestCase
  setup do
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
  end

  teardown do
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
    Payments::CacheCounter.clear_circuit!
  end

  def stubbed_adapter(response_or_block)
    adapter = Payments::TbankAdapter.new
    if response_or_block.respond_to?(:call)
      adapter.define_singleton_method(:post_json, &response_or_block)
    else
      adapter.define_singleton_method(:post_json) do |_url, _payload|
        response_or_block
      end
    end
    adapter
  end

  test "call! posts GetQr with PAYMENT_LINK and returns nspk payment_url" do
    captured = nil
    adapter = stubbed_adapter(lambda { |url, payload|
      captured = { url: url, payload: payload }
      {
        "Success" => true,
        "ErrorCode" => "0",
        "Data" => "https://qr.nspk.ru/AS10000TESTLINK",
        "PaymentId" => "pay-77"
      }
    })

    result = Payments::TbankQrFetcher.call!(payment_id: "pay-77", adapter: adapter)

    assert captured[:url].end_with?("/GetQr")
    assert_equal "pay-77", captured[:payload]["PaymentId"]
    assert_equal "PAYMENT_LINK", captured[:payload]["DataType"]
    assert_equal "TestTerminal", captured[:payload]["TerminalKey"]
    assert captured[:payload]["Token"].present?
    assert_equal "https://qr.nspk.ru/AS10000TESTLINK", result[:payment_url]
    assert_equal "https://qr.nspk.ru/AS10000TESTLINK", result[:data]
  end

  test "call! raises ApiError on bank validation failure" do
    adapter = stubbed_adapter(
      "Success" => false,
      "ErrorCode" => "7",
      "Message" => "Неверный PaymentId"
    )

    error = assert_raises(Payments::TbankAdapter::ApiError) do
      Payments::TbankQrFetcher.call!(payment_id: "bad-id", adapter: adapter)
    end
    assert_equal "7", error.error_code
  end

  test "call! raises Error when Data is blank" do
    adapter = stubbed_adapter(
      "Success" => true,
      "ErrorCode" => "0",
      "Data" => ""
    )

    assert_raises(Payments::TbankQrFetcher::Error) do
      Payments::TbankQrFetcher.call!(payment_id: "pay-1", adapter: adapter)
    end
  end

  test "call! raises Error when payment_id is blank" do
    assert_raises(Payments::TbankQrFetcher::Error) do
      Payments::TbankQrFetcher.call!(payment_id: "  ")
    end
  end

  test "call! wraps transport Error from adapter" do
    adapter = stubbed_adapter(lambda { |_url, _payload|
      raise Payments::TbankAdapter::Error, "Таймаут запроса к Т-Банку"
    })

    error = assert_raises(Payments::TbankAdapter::Error) do
      Payments::TbankQrFetcher.call!(payment_id: "pay-1", adapter: adapter)
    end
    assert_match(/Таймаут/i, error.message)
  end
end
