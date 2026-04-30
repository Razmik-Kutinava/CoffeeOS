# frozen_string_literal: true

# BACK-006: Исправляем RLS-политику rls_pts_isolation для franchise_manager.
# Раньше franchise_manager не видел product_tenant_settings, хотя должен видеть
# цены и настройки товаров в своей организации.
class FixRlsProductTenantSettingsFranchiseIsolation < ActiveRecord::Migration[8.1]
  def up
    # Удаляем старую политику
    execute <<-SQL
      DROP POLICY IF EXISTS rls_pts_isolation ON product_tenant_settings;
    SQL

    # Создаем новую политику с franchise_manager
    execute <<-SQL
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
    SQL
  end

  def down
    # Возвращаем старую политику (без franchise_manager)
    execute <<-SQL
      DROP POLICY IF EXISTS rls_pts_isolation ON product_tenant_settings;

      CREATE POLICY rls_pts_isolation ON product_tenant_settings
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'office_manager')
          )
        );
    SQL
  end
end
