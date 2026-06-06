# frozen_string_literal: true

require "test_helper"

class Shop::PaymentConfigTest < ActiveSupport::TestCase
  setup do
    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    @old_iframe = ENV["SHOP_PAYMENT_IFRAME"]
    @old_key = ENV["TBANK_TERMINAL_KEY"]
  end

  teardown do
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    ENV["SHOP_PAYMENT_IFRAME"] = @old_iframe
    ENV["TBANK_TERMINAL_KEY"] = @old_key
  end

  test "simulate disables iframe" do
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
    ENV["SHOP_PAYMENT_IFRAME"] = "1"
    refute Shop::PaymentConfig.iframe_enabled?
    assert Shop::PaymentConfig.client_json[:simulate]
  end

  test "iframe enabled when simulate off and flag on" do
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["SHOP_PAYMENT_IFRAME"] = "1"
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    assert Shop::PaymentConfig.iframe_enabled?
    json = Shop::PaymentConfig.client_json
    assert json[:iframe]
    assert_equal "TestTerminal", json[:terminal_key]
  end
end
