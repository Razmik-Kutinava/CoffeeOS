# frozen_string_literal: true

require "test_helper"

class Shop::PaymentCryptoConfigTest < ActiveSupport::TestCase
  test "rsa_public_key reads TBANK_RSA_PUBLIC_KEY" do
    pem = "-----BEGIN PUBLIC KEY-----\nTEST\n-----END PUBLIC KEY-----"
    with_env("TBANK_RSA_PUBLIC_KEY" => pem) do
      assert_equal pem, Shop::PaymentCryptoConfig.rsa_public_key
      json = Shop::PaymentCryptoConfig.as_api_json
      assert json[:card_data_ready]
      assert_equal pem, json[:rsa_public_key]
    end
  end

  test "as_api_json when key missing" do
    with_env("TBANK_RSA_PUBLIC_KEY" => nil) do
      json = Shop::PaymentCryptoConfig.as_api_json
      assert_not json[:card_data_ready]
      assert_nil json[:rsa_public_key]
    end
  end

  private

  def with_env(overrides)
    saved = {}
    overrides.each do |k, v|
      saved[k] = ENV[k]
      if v.nil?
        ENV.delete(k)
      else
        ENV[k] = v
      end
    end
    yield
  ensure
    saved.each do |k, v|
      if v.nil?
        ENV.delete(k)
      else
        ENV[k] = v
      end
    end
  end
end
