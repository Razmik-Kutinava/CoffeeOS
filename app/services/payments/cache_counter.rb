#!/usr/bin/env ruby
# frozen_string_literal: true

# SolidCache не поддерживает increment (см. ISSUES 2026-05-01, rack_attack.rb).
# Счётчик через read/write — достаточно для circuit breaker на Fly.
module Payments
  module CacheCounter
    module_function

    def read(key)
      Rails.cache.read(key).to_i
    end

    def increment(key, expires_in:)
      count = read(key) + 1
      Rails.cache.write(key, count, expires_in: expires_in)
      count
    end

    def delete(key)
      Rails.cache.delete(key)
    end

    def present?(key)
      Rails.cache.read(key).present?
    end
  end
end
