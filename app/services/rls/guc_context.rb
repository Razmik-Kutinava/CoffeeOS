# frozen_string_literal: true

module Rls
  # Узкие временные GUC для обхода tenant RLS без `row_security off`.
  # Канон: auth_login (users) · device_token_lookup (kiosk/TV/cable).
  class GucContext
    def self.with_auth_login
      with_local_guc("app.auth_login", "on") { yield }
    end

    def self.with_device_token_lookup
      with_local_guc("app.device_token_lookup", "on") { yield }
    end

    def self.with_local_guc(key, value)
      conn = ActiveRecord::Base.connection
      validate_guc_key!(key)
      sql = case key
      when "app.auth_login"
        "SET LOCAL app.auth_login = #{conn.quote(value)}"
      when "app.device_token_lookup"
        "SET LOCAL app.device_token_lookup = #{conn.quote(value)}"
      else
        raise ArgumentError, "unsupported RLS GUC: #{key}"
      end
      ActiveRecord::Base.transaction do
        conn.execute(sql)
        yield
      end
    end

    def self.validate_guc_key!(key)
      return if %w[app.auth_login app.device_token_lookup].include?(key)

      raise ArgumentError, "unsupported RLS GUC: #{key}"
    end
    private_class_method :validate_guc_key!
  end
end
