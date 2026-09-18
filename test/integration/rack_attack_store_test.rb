# frozen_string_literal: true

require "test_helper"

# TASK_93-I — Rack::Attack shared store (Redis on prod/FLY)
class RackAttackStoreTest < ActiveSupport::TestCase
  test "T-I1a production/FLY with REDIS_URL uses RedisCacheStore not MemoryStore" do
    assert Rack::Attack.respond_to?(:resolve_cache_store),
           "Rack::Attack.resolve_cache_store missing (TASK_93-I R1)"

    store = Rack::Attack.resolve_cache_store(
      production: true,
      fly_app_name: "coffeeos",
      rack_attack_redis_url: nil,
      redis_url: "redis://127.0.0.1:6379/15"
    )

    refute_kind_of ActiveSupport::Cache::MemoryStore, store
    assert_kind_of ActiveSupport::Cache::RedisCacheStore, store
  end

  test "T-I1b increment is shared across two store handles to same Redis" do
    url = ENV["RACK_ATTACK_REDIS_URL"].presence || ENV["REDIS_URL"].presence
    skip "REDIS_URL / RACK_ATTACK_REDIS_URL not set (R9)" if url.blank?
    assert Rack::Attack.respond_to?(:resolve_cache_store)

    store_a = Rack::Attack.resolve_cache_store(
      production: true,
      fly_app_name: "coffeeos",
      rack_attack_redis_url: nil,
      redis_url: url
    )
    store_b = Rack::Attack.resolve_cache_store(
      production: true,
      fly_app_name: "coffeeos",
      rack_attack_redis_url: nil,
      redis_url: url
    )

    key = "rack-attack-ti1b-#{SecureRandom.hex(8)}"
    store_a.delete(key) if store_a.respond_to?(:delete)
    store_a.increment(key, 1, expires_in: 60)
    second = store_b.increment(key, 1, expires_in: 60)
    assert_equal 2, second.to_i
  ensure
    if defined?(store_a) && store_a && key
      store_a.delete(key) if store_a.respond_to?(:delete)
    end
  end

  test "T-I1c production/FLY without Redis URL fails boot (raise)" do
    assert Rack::Attack.respond_to?(:resolve_cache_store)

    assert_raises(RuntimeError) do
      Rack::Attack.resolve_cache_store(
        production: true,
        fly_app_name: "coffeeos",
        rack_attack_redis_url: nil,
        redis_url: nil
      )
    end
  end

  test "T-I1 dev without URL returns MemoryStore" do
    assert Rack::Attack.respond_to?(:resolve_cache_store)

    store = Rack::Attack.resolve_cache_store(
      production: false,
      fly_app_name: nil,
      rack_attack_redis_url: nil,
      redis_url: nil
    )
    assert_kind_of ActiveSupport::Cache::MemoryStore, store
  end
end
