# frozen_string_literal: true

# BACK-005: Исправляем RLS-политику rls_payments_isolation для franchise_manager.
# Раньше franchise_manager видел все платежи сети без фильтрации по organization_id.
# Теперь добавляем фильтр по organization_id через JOIN с users и tenants.
class FixRlsPaymentsFranchiseIsolation < ActiveRecord::Migration[8.1]
  def up
    # Удаляем старую политику
    execute <<-SQL
      DROP POLICY IF EXISTS rls_payments_isolation ON payments;
    SQL

    # Создаём новую политику с фильтром по organization_id для franchise_manager
    # Роли хранятся в user_roles + roles (many-to-many), organization_id в users
    execute <<-SQL
      CREATE POLICY rls_payments_isolation ON payments
      FOR ALL
      USING (
        tenant_id = current_setting('app.current_tenant_id')::uuid
        OR (
          current_setting('app.current_user_id', true) IS NOT NULL
          AND EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON r.id = ur.role_id
            JOIN users u ON u.id = ur.user_id
            WHERE ur.user_id = current_setting('app.current_user_id')::uuid
            AND r.code = 'franchise_manager'
            AND u.organization_id = (
              SELECT organization_id FROM tenants WHERE tenants.id = payments.tenant_id
            )
          )
        )
      );
    SQL
  end

  def down
    # Возвращаем старую политику (без фильтра по organization_id)
    execute <<-SQL
      DROP POLICY IF EXISTS rls_payments_isolation ON payments;

      CREATE POLICY rls_payments_isolation ON payments
      FOR ALL
      USING (
        tenant_id = current_setting('app.current_tenant_id')::uuid
        OR (
          current_setting('app.current_user_id', true) IS NOT NULL
          AND EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON r.id = ur.role_id
            WHERE ur.user_id = current_setting('app.current_user_id')::uuid
            AND r.code IN ('franchise_manager', 'uk_global_admin')
          )
        )
      );
    SQL
  end
end
