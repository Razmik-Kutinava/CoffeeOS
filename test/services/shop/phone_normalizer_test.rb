# frozen_string_literal: true

require "test_helper"

class Shop::PhoneNormalizerTest < ActiveSupport::TestCase
  test "normalizes 8XXXXXXXXXX to +7" do
    assert_equal "+79001234567", Shop::PhoneNormalizer.normalize!("89001234567")
  end

  test "normalizes 7XXXXXXXXXX to +7" do
    assert_equal "+79001234567", Shop::PhoneNormalizer.normalize!("79001234567")
  end

  test "normalizes formatted +7 with spaces and parens" do
    assert_equal "+79001234567", Shop::PhoneNormalizer.normalize!("+7 (900) 123-45-67")
  end

  test "rejects invalid short number" do
    assert_raises(Shop::PhoneNormalizer::Error) do
      Shop::PhoneNormalizer.normalize!("12345")
    end
  end

  test "rejects non-russian country code" do
    assert_raises(Shop::PhoneNormalizer::Error) do
      Shop::PhoneNormalizer.normalize!("+19991234567")
    end
  end
end
