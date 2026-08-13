# frozen_string_literal: true

class CreateAdminAuditAndFeatureFlagsLogs < ActiveRecord::Migration[8.1]
  def up
    create_table :admin_audit_logs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :actor, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :entity_type, null: false, limit: 100
      t.uuid :entity_id
      t.string :action, null: false, limit: 50
      t.jsonb :details, null: false, default: {}
      t.string :request_id, limit: 128
      t.timestamps
    end

    add_index :admin_audit_logs, [ :tenant_id, :created_at ], if_not_exists: true
    add_index :admin_audit_logs, [ :tenant_id, :entity_type, :entity_id ], if_not_exists: true
    add_index :admin_audit_logs, :action, if_not_exists: true
    add_index :admin_audit_logs, :request_id, if_not_exists: true
    add_index :admin_audit_logs, :details, using: :gin, if_not_exists: true

    execute "COMMENT ON TABLE admin_audit_logs IS 'Журнал административных действий УК/менеджмента'"

    create_table :feature_flags_logs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :changed_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :module, null: false, limit: 100
      t.string :action, null: false, limit: 20
      t.boolean :enabled, null: false
      t.timestamp :changed_at, null: false, default: -> { "NOW()" }
      t.jsonb :meta, null: false, default: {}
      t.timestamps
    end

    add_index :feature_flags_logs, [ :tenant_id, :module, :changed_at ], if_not_exists: true
    add_index :feature_flags_logs, :action, if_not_exists: true
    add_index :feature_flags_logs, :changed_by_id, if_not_exists: true
    add_index :feature_flags_logs, :meta, using: :gin, if_not_exists: true

    execute "COMMENT ON TABLE feature_flags_logs IS 'История изменений feature_flags по точкам'"
  end

  def down
    drop_table :feature_flags_logs, if_exists: true
    drop_table :admin_audit_logs, if_exists: true
  end
end
