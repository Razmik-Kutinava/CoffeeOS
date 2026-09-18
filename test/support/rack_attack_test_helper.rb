# frozen_string_literal: true

# Isolated Attack counters for throttle assertions.
# CI sets REDIS_URL → RedisCacheStore is shared across parallel workers and flakes 429 tests.
module RackAttackTestHelper
  def with_rack_attack
    was_enabled = Rack::Attack.enabled
    was_store = Rack::Attack.cache.store
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rack::Attack.cache.store = was_store
    Rack::Attack.enabled = was_enabled
  end
end
