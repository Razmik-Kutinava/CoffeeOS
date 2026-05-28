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
end
