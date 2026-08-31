# frozen_string_literal: true

# IB Phase 6 prep: lookup device по глобальному token до SET LOCAL tenant GUC.
# Заменяет app-level `SET LOCAL row_security = off` на узкую RLS-политику (как app.auth_login).
class AddRlsDevicesTokenLookupPolicy < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      CREATE POLICY rls_devices_token_lookup ON devices
        FOR SELECT
        USING (NULLIF(current_setting('app.device_token_lookup', true), '') = 'on');
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS rls_devices_token_lookup ON devices"
  end
end
