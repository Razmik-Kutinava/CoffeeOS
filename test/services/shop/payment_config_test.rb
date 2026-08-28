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

  test "simulate defaults to false when env unset" do
    ENV.delete("SHOP_SIMULATE_PAYMENT")
    refute Shop::PaymentConfig.simulate?
  end

  test "simulate raises in production when enabled" do
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
    saved_env = Rails.env
    Rails.singleton_class.define_method(:env) { ActiveSupport::StringInquirer.new("production") }
    begin
      error = assert_raises(RuntimeError) { Shop::PaymentConfig.simulate? }
      assert_match(/must not be enabled in production/, error.message)
    ensure
      Rails.singleton_class.define_method(:env) { saved_env }
    end
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
