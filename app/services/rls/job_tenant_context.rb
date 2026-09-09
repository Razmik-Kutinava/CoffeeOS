# frozen_string_literal: true

module Rls
  # Tenant GUC for Solid Queue / ActiveJob workers.
  # Tenant always comes from a loaded record (or its tenant_id), never from raw HTTP args.
  #
  # Uses SET LOCAL when already inside a transaction; otherwise session SET + RESET
  # so long job bodies (FCM/SMS) do not force one outer DB transaction that would
  # roll back committed claims (e.g. ReadyPushClaim).
  class JobTenantContext
    def self.with(record)
      raise ArgumentError, "record required" if record.nil?

      tenant_id = record.try(:tenant_id)
      raise ArgumentError, "tenant_id required" if tenant_id.blank?

      with_tenant_id(tenant_id) { yield }
    end

    def self.with_tenant_id(tenant_id)
      raise ArgumentError, "tenant_id required" if tenant_id.blank?

      previous_tid = Current.tenant_id
      previous_uid = Current.user_id
      Current.tenant_id = tenant_id
      Current.user_id = nil

      conn = ActiveRecord::Base.connection
      used_session_set = !conn.transaction_open?
      begin
        apply_tenant_guc!(conn, tenant_id)
        yield
      ensure
        reset_tenant_guc!(conn) if used_session_set
        Current.tenant_id = previous_tid
        Current.user_id = previous_uid
      end
    end

    def self.apply_tenant_guc!(conn, tenant_id)
      quoted = conn.quote(tenant_id.to_s)
      sql = if conn.transaction_open?
        "SET LOCAL app.current_tenant_id = #{quoted}"
      else
        "SET app.current_tenant_id = #{quoted}"
      end
      conn.execute(sql)
    rescue ActiveRecord::StatementInvalid => e
      # Dev/test may run without custom GUCs — Current.tenant_id still set.
      raise unless e.message.include?("unrecognized configuration parameter")
    end
    private_class_method :apply_tenant_guc!

    def self.reset_tenant_guc!(conn)
      conn.execute("RESET app.current_tenant_id")
    rescue ActiveRecord::StatementInvalid, PG::Error
      nil
    end
    private_class_method :reset_tenant_guc!
  end
end
