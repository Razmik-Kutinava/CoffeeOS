# frozen_string_literal: true

# Test DB из schema.rb не содержит DDL политик RLS из migrate#execute.
# Повторно применяем существующие миграции политик (не новые — STOP-LIST roadmap).
module RlsTestBootstrap
  MVP_TABLES = %w[
    orders
    payments
    product_tenant_settings
    cash_shifts
    ingredient_tenant_stocks
    stock_movements
  ].freeze

  TEST_ROLE = "coffeeos_rls_test"

  module_function

  def ensure_policies!
    conn = ActiveRecord::Base.connection
    return if policies_bootstrapped?(conn)

    enable_rls_on_mvp_tables!(conn)

    require Rails.root.join("db/migrate/20260320120001_rls_franchise_organization_scope.rb")
    RlsFranchiseOrganizationScope.new.up

    require Rails.root.join("db/migrate/20260424000002_fix_rls_payments_franchise_isolation.rb")
    FixRlsPaymentsFranchiseIsolation.new.up

    require Rails.root.join("db/migrate/20260520000002_fix_rls_policies_office_manager_to_general_manager.rb")
    FixRlsPoliciesOfficeManagerToGeneralManager.new.up

    apply_cash_shifts_policy!(conn)
    apply_stock_movements_policy!(conn)
    apply_devices_token_lookup_policy!(conn)
  end

  def policies_bootstrapped?(conn)
    conn.select_value("SELECT COUNT(*) FROM pg_policies WHERE tablename = 'orders'").to_i.positive?
  end

  def ensure_test_role!(conn)
    unless test_role_exists?(conn)
      begin
        conn.execute <<~SQL.squish
          CREATE ROLE #{TEST_ROLE} LOGIN PASSWORD 'test' NOSUPERUSER NOBYPASSRLS
        SQL
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::StatementInvalid => e
        # Parallel workers can race on CREATE ROLE; ignore duplicate.
        raise unless e.message.match?(/already exists|duplicate|UniqueViolation/i) ||
                     e.cause.is_a?(PG::UniqueViolation)
      end
    end

    conn.execute("GRANT USAGE ON SCHEMA public TO #{TEST_ROLE}")
    conn.execute("GRANT SELECT ON ALL TABLES IN SCHEMA public TO #{TEST_ROLE}")
    conn.execute("GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO #{TEST_ROLE}")
  end

  def test_role_exists?(conn)
    conn.select_value("SELECT 1 FROM pg_roles WHERE rolname = #{conn.quote(TEST_ROLE)}").present?
  end

  def enable_rls_on_mvp_tables!(conn)
    MVP_TABLES.each do |table|
      next unless conn.table_exists?(table)

      conn.execute("ALTER TABLE #{conn.quote_table_name(table)} ENABLE ROW LEVEL SECURITY")
      conn.execute("ALTER TABLE #{conn.quote_table_name(table)} FORCE ROW LEVEL SECURITY")
    end
  end

  def apply_cash_shifts_policy!(conn)
    return unless conn.table_exists?("cash_shifts")

    conn.execute("DROP POLICY IF EXISTS rls_cash_shifts_isolation ON cash_shifts")
    conn.execute <<-SQL.squish
      CREATE POLICY rls_cash_shifts_isolation ON cash_shifts
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
  end

  def apply_stock_movements_policy!(conn)
    return unless conn.table_exists?("stock_movements")

    conn.execute("DROP POLICY IF EXISTS rls_stock_movements_isolation ON stock_movements")
    conn.execute <<-SQL.squish
      CREATE POLICY rls_stock_movements_isolation ON stock_movements
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
  end

  def apply_devices_token_lookup_policy!(conn)
    return unless conn.table_exists?("devices")

    conn.execute("DROP POLICY IF EXISTS rls_devices_token_lookup ON devices")
    conn.execute <<-SQL.squish
      CREATE POLICY rls_devices_token_lookup ON devices
        FOR SELECT
        USING (NULLIF(current_setting('app.device_token_lookup', true), '') = 'on')
    SQL
  end
end
