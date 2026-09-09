# frozen_string_literal: true

module Rls
  # Узкие временные GUC для обхода tenant RLS без `row_security off`.
  # Канон: auth_login · device_token_lookup · shop_api_key_lookup.
  # SET LOCAL strings hardcoded (allowlist) — Brakeman SQL injection gate.
  class GucContext
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
      sql = case key
      when "app.auth_login"
        "SET LOCAL app.auth_login = #{conn.quote(value)}"
      when "app.device_token_lookup"
        "SET LOCAL app.device_token_lookup = #{conn.quote(value)}"
      when "app.shop_api_key_lookup"
        "SET LOCAL app.shop_api_key_lookup = #{conn.quote(value)}"
      else
        raise ArgumentError, "unsupported RLS GUC: #{key}"
      end
      ActiveRecord::Base.transaction do
        conn.execute(sql)
        yield
      end
    end
  end
end
