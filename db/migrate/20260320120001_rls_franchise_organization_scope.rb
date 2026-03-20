# frozen_string_literal: true

# franchise_manager: только строки своей organization (через tenants.organization_id).
# ук_global_admin: без ограничения по тенанту для этих политик.
class RlsFranchiseOrganizationScope < ActiveRecord::Migration[8.1]
  def up
    execute "DROP POLICY IF EXISTS rls_users_isolation ON users"
    execute "DROP POLICY IF EXISTS rls_user_roles_isolation ON user_roles"
    execute "DROP POLICY IF EXISTS rls_orders_isolation ON orders"
    execute "DROP POLICY IF EXISTS rls_order_items_isolation ON order_items"
    execute "DROP POLICY IF EXISTS rls_payments_isolation ON payments"

    execute <<-SQL
      CREATE POLICY rls_users_isolation ON users
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code = 'ук_global_admin'
          )
          OR (
            EXISTS (
              SELECT 1 FROM users u_fm
              JOIN user_roles ur_fm ON ur_fm.user_id = u_fm.id
              JOIN roles r_fm ON r_fm.id = ur_fm.role_id AND r_fm.code = 'franchise_manager'
              WHERE u_fm.id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
              AND u_fm.organization_id IS NOT NULL
            )
            AND (
              users.id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
              OR users.tenant_id IN (
                SELECT t.id FROM tenants t
                WHERE t.organization_id = (
                  SELECT u2.organization_id FROM users u2
                  WHERE u2.id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                  LIMIT 1
                )
              )
            )
          )
        )
    SQL

    execute <<-SQL
      CREATE POLICY rls_user_roles_isolation ON user_roles
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code = 'ук_global_admin'
          )
          OR (
            EXISTS (
              SELECT 1 FROM users u_fm
              JOIN user_roles ur_fm ON ur_fm.user_id = u_fm.id
              JOIN roles r_fm ON r_fm.id = ur_fm.role_id AND r_fm.code = 'franchise_manager'
              WHERE u_fm.id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
              AND u_fm.organization_id IS NOT NULL
            )
            AND (
              user_roles.tenant_id IS NOT NULL
              AND user_roles.tenant_id IN (
                SELECT t.id FROM tenants t
                WHERE t.organization_id = (
                  SELECT u2.organization_id FROM users u2
                  WHERE u2.id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                  LIMIT 1
                )
              )
            )
          )
        )
    SQL

    execute <<-SQL
      CREATE POLICY rls_orders_isolation ON orders
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code = 'ук_global_admin'
          )
          OR (
            EXISTS (
              SELECT 1 FROM users u_fm
              JOIN user_roles ur_fm ON ur_fm.user_id = u_fm.id
              JOIN roles r_fm ON r_fm.id = ur_fm.role_id AND r_fm.code = 'franchise_manager'
              WHERE u_fm.id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
              AND u_fm.organization_id IS NOT NULL
            )
            AND EXISTS (
              SELECT 1 FROM tenants t
              WHERE t.id = orders.tenant_id
              AND t.organization_id = (
                SELECT u2.organization_id FROM users u2
                WHERE u2.id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                LIMIT 1
              )
            )
          )
        )
    SQL

    execute <<-SQL
      CREATE POLICY rls_order_items_isolation ON order_items
        FOR ALL
        USING (
          EXISTS (
            SELECT 1 FROM orders o
            WHERE o.id = order_items.order_id
            AND (
              o.tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
              OR EXISTS (
                SELECT 1 FROM user_roles ur
                JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                AND r.code = 'ук_global_admin'
              )
              OR (
                EXISTS (
                  SELECT 1 FROM users u_fm
                  JOIN user_roles ur_fm ON ur_fm.user_id = u_fm.id
                  JOIN roles r_fm ON r_fm.id = ur_fm.role_id AND r_fm.code = 'franchise_manager'
                  WHERE u_fm.id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                  AND u_fm.organization_id IS NOT NULL
                )
                AND EXISTS (
                  SELECT 1 FROM tenants t
                  WHERE t.id = o.tenant_id
                  AND t.organization_id = (
                    SELECT u2.organization_id FROM users u2
                    WHERE u2.id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                    LIMIT 1
                  )
                )
              )
            )
          )
        )
    SQL

    execute <<-SQL
      CREATE POLICY rls_payments_isolation ON payments
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code = 'ук_global_admin'
          )
          OR (
            EXISTS (
              SELECT 1 FROM users u_fm
              JOIN user_roles ur_fm ON ur_fm.user_id = u_fm.id
              JOIN roles r_fm ON r_fm.id = ur_fm.role_id AND r_fm.code = 'franchise_manager'
              WHERE u_fm.id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
              AND u_fm.organization_id IS NOT NULL
            )
            AND EXISTS (
              SELECT 1 FROM tenants t
              WHERE t.id = payments.tenant_id
              AND t.organization_id = (
                SELECT u2.organization_id FROM users u2
                WHERE u2.id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                LIMIT 1
              )
            )
          )
        )
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS rls_payments_isolation ON payments"
    execute "DROP POLICY IF EXISTS rls_order_items_isolation ON order_items"
    execute "DROP POLICY IF EXISTS rls_orders_isolation ON orders"
    execute "DROP POLICY IF EXISTS rls_user_roles_isolation ON user_roles"
    execute "DROP POLICY IF EXISTS rls_users_isolation ON users"

    execute <<-SQL
      CREATE POLICY rls_users_isolation ON users
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'franchise_manager')
          )
        )
    SQL

    execute <<-SQL
      CREATE POLICY rls_user_roles_isolation ON user_roles
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'franchise_manager')
          )
        )
    SQL

    execute <<-SQL
      CREATE POLICY rls_orders_isolation ON orders
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'franchise_manager')
          )
        )
    SQL

    execute <<-SQL
      CREATE POLICY rls_order_items_isolation ON order_items
        FOR ALL
        USING (
          EXISTS (
            SELECT 1 FROM orders o
            WHERE o.id = order_items.order_id
            AND o.tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          )
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'franchise_manager')
          )
        )
    SQL

    execute <<-SQL
      CREATE POLICY rls_payments_isolation ON payments
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'franchise_manager')
          )
        )
    SQL
  end
end
