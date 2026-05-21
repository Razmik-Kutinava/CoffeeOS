# frozen_string_literal: true

# После переименования роли office_manager → general_manager (20260520000001)
# две RLS-политики хранили старый code 'office_manager' в SQL-строке.
# Пересоздаём их с актуальным 'general_manager'.
class FixRlsPoliciesOfficeManagerToGeneralManager < ActiveRecord::Migration[8.1]
  def up
    # --- product_tenant_settings ---
    # Последнее состояние: 20260428000002 (office_manager + franchise_manager)
    execute <<~SQL
      DROP POLICY IF EXISTS rls_pts_isolation ON product_tenant_settings;

      CREATE POLICY rls_pts_isolation ON product_tenant_settings
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'general_manager', 'franchise_manager')
          )
        );
    SQL

    # --- ingredient_tenant_stocks ---
    # Создана в 20250115000005 с office_manager
    execute <<~SQL
      DROP POLICY IF EXISTS rls_stock_isolation ON ingredient_tenant_stocks;

      CREATE POLICY rls_stock_isolation ON ingredient_tenant_stocks
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'general_manager', 'prep_kitchen_manager')
          )
        );
    SQL
  end

  def down
    execute <<~SQL
      DROP POLICY IF EXISTS rls_pts_isolation ON product_tenant_settings;

      CREATE POLICY rls_pts_isolation ON product_tenant_settings
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'office_manager', 'franchise_manager')
          )
        );

      DROP POLICY IF EXISTS rls_stock_isolation ON ingredient_tenant_stocks;

      CREATE POLICY rls_stock_isolation ON ingredient_tenant_stocks
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'office_manager', 'prep_kitchen_manager')
          )
        );
    SQL
  end
end
