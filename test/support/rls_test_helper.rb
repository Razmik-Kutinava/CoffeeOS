# frozen_string_literal: true

require_relative "rls_test_bootstrap"

module RlsTestHelper
  TENANT_ISOLATED_TABLES = RlsTestBootstrap::MVP_TABLES

  def enable_rls_on_mvp_tables!
    RlsTestBootstrap.ensure_policies!
    conn = ActiveRecord::Base.connection
    RlsTestBootstrap.ensure_test_role!(conn)
    RlsTestBootstrap.enable_rls_on_mvp_tables!(conn)
  end

  def disable_rls_on_mvp_tables!
    conn = ActiveRecord::Base.connection
    TENANT_ISOLATED_TABLES.each do |table|
      next unless conn.table_exists?(table)

      conn.execute("ALTER TABLE #{conn.quote_table_name(table)} DISABLE ROW LEVEL SECURITY")
    end
    conn.execute("RESET ROLE") rescue nil
  end

  def with_rls_tenant_context(tenant_id:, user_id:)
    enable_rls_on_mvp_tables!
    conn = ActiveRecord::Base.connection
    previous_tid = Current.tenant_id
    previous_uid = Current.user_id

    conn.transaction do
      conn.execute("SET LOCAL ROLE #{RlsTestBootstrap::TEST_ROLE}")
      conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant_id.to_s)}")
      conn.execute("SET LOCAL app.current_user_id = #{conn.quote(user_id.to_s)}")
      Current.tenant_id = tenant_id
      Current.user_id = user_id
      yield
    end
  ensure
    conn&.execute("RESET ROLE") rescue nil
    Current.tenant_id = previous_tid
    Current.user_id = previous_uid
    disable_rls_on_mvp_tables!
  end
end
