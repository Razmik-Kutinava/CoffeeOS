# frozen_string_literal: true

module Rls
  # Узкие временные GUC для обхода tenant RLS без `row_security off`.
  # Канон: auth_login · device_token_lookup · shop_api_key_lookup.
  class GucContext
    SUPPORTED = %w[
      app.auth_login
      app.device_token_lookup
      app.shop_api_key_lookup
    ].freeze

    def self.with_auth_login
      with_local_guc("app.auth_login", "on") { yield }
    end

    def self.with_device_token_lookup
      with_local_guc("app.device_token_lookup", "on") { yield }
    end

    def self.with_shop_api_key_lookup
      with_local_guc("app.shop_api_key_lookup", "on") { yield }
    end

    def self.with_local_guc(key, value)
      conn = ActiveRecord::Base.connection
      validate_guc_key!(key)
      sql = "SET LOCAL #{key} = #{conn.quote(value)}"
      ActiveRecord::Base.transaction do
        conn.execute(sql)
        yield
      end
    end

    def self.validate_guc_key!(key)
      return if SUPPORTED.include?(key)

      raise ArgumentError, "unsupported RLS GUC: #{key}"
    end
    private_class_method :validate_guc_key!
  end
end
