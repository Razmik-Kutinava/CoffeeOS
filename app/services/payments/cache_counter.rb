# frozen_string_literal: true

# SolidCache на Fly: increment ломается, key_hash может давать RangeError (ISSUES 2026-05-01).
# Circuit breaker — MemoryStore (как Rack::Attack), same-pod.
# T‑Bank webhook idempotency — Rails.cache в TbankController (не этот STORE).
module Payments
  module CacheCounter
    STORE = ActiveSupport::Cache::MemoryStore.new
    MUTEX = Mutex.new

    module_function

    def read(key)
      STORE.read(key).to_i
    end

    def write(key, value, expires_in:)
      STORE.write(key, value, expires_in: expires_in)
    end

    def increment(key, expires_in:)
      MUTEX.synchronize do
        count = read(key) + 1
        write(key, count, expires_in: expires_in)
        count
      end
    end

    def delete(key)
      MUTEX.synchronize { STORE.delete(key) }
    end

    def present?(key)
      STORE.read(key).present?
    end

    # Резервирует ключ (same-pod atomic dedup). Возвращает false если ключ уже занят.
    def claim(key, expires_in:)
      return false if key.blank?

      MUTEX.synchronize do
        return false if present?(key)

        write(key, 1, expires_in: expires_in)
        true
      end
    end

    def clear_circuit!
      delete(Payments::TbankAdapter::CB_FAILURES_KEY)
      delete(Payments::TbankAdapter::CB_OPEN_KEY)
    end

    def clear!
      MUTEX.synchronize { STORE.clear }
    end
  end
end
