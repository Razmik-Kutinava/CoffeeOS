# frozen_string_literal: true

# SolidCache на Fly: increment ломается, key_hash может давать RangeError (ISSUES 2026-05-01).
# Circuit breaker — отдельный MemoryStore (как Rack::Attack), достаточно для одной машины Fly.
module Payments
  module CacheCounter
    STORE = ActiveSupport::Cache::MemoryStore.new

    module_function

    def read(key)
      STORE.read(key).to_i
    end

    def write(key, value, expires_in:)
      STORE.write(key, value, expires_in: expires_in)
    end

    def increment(key, expires_in:)
      count = read(key) + 1
      write(key, count, expires_in: expires_in)
      count
    end

    def delete(key)
      STORE.delete(key)
    end

    def present?(key)
      STORE.read(key).present?
    end

    def clear_circuit!
      delete(Payments::TbankAdapter::CB_FAILURES_KEY)
      delete(Payments::TbankAdapter::CB_OPEN_KEY)
    end

    def clear!
      STORE.clear
    end
  end
end
