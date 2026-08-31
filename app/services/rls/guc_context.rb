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
      ActiveRecord::Base.transaction do
        conn.execute("SET LOCAL #{key} = #{conn.quote(value)}")
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
