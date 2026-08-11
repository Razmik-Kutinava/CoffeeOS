# frozen_string_literal: true

require "test_helper"

class Payments::CacheCounterTest < ActiveSupport::TestCase
  test "increment uses read/write when cache store lacks native increment" do
    key = "test:cb:failures:#{SecureRandom.hex(4)}"
    assert_equal 1, Payments::CacheCounter.increment(key, expires_in: 1.minute)
    assert_equal 2, Payments::CacheCounter.increment(key, expires_in: 1.minute)
  ensure
    Payments::CacheCounter.delete(key)
  end

  test "claim is exclusive for the same key" do
    key = "test:claim:#{SecureRandom.hex(4)}"
    assert Payments::CacheCounter.claim(key, expires_in: 1.minute)
    assert_not Payments::CacheCounter.claim(key, expires_in: 1.minute)
    assert Payments::CacheCounter.present?(key)
  ensure
    Payments::CacheCounter.delete(key)
  end

  test "blank key is never claimed" do
    assert_not Payments::CacheCounter.claim(nil, expires_in: 1.minute)
    assert_not Payments::CacheCounter.claim("", expires_in: 1.minute)
  end

  test "delete releases claim for a new claim" do
    key = "test:claim:release:#{SecureRandom.hex(4)}"
    assert Payments::CacheCounter.claim(key, expires_in: 1.minute)
    Payments::CacheCounter.delete(key)
    assert Payments::CacheCounter.claim(key, expires_in: 1.minute)
  ensure
    Payments::CacheCounter.delete(key)
  end
end
