# frozen_string_literal: true

# Логин до сессии: нет app.current_tenant_id — SELECT users/user_roles иначе пустой (RLS).
class AddRlsAuthLoginPolicies < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      CREATE POLICY rls_users_auth_login ON users
        FOR SELECT
        USING (NULLIF(current_setting('app.auth_login', true), '') = 'on');
    SQL

    execute <<-SQL
      CREATE POLICY rls_user_roles_auth_login ON user_roles
        FOR SELECT
        USING (NULLIF(current_setting('app.auth_login', true), '') = 'on');
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS rls_user_roles_auth_login ON user_roles"
    execute "DROP POLICY IF EXISTS rls_users_auth_login ON users"
  end
end
