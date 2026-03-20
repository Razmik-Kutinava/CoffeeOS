# frozen_string_literal: true

class RlsFeatureFlagsUkGlobalAdmin < ActiveRecord::Migration[8.1]
  def up
    execute "DROP POLICY IF EXISTS rls_feature_flags_isolation ON feature_flags"
    execute <<-SQL
      CREATE POLICY rls_feature_flags_isolation ON feature_flags
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code = 'ук_global_admin'
          )
        )
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS rls_feature_flags_isolation ON feature_flags"
    execute <<-SQL
      CREATE POLICY rls_feature_flags_isolation ON feature_flags
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
  end
end
