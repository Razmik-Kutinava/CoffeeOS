class CreateStage6Kiosk < ActiveRecord::Migration[8.1]
  def up
    # Таблица kiosk_settings (настройки киоска)
    create_table :kiosk_settings, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :device, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :is_active, default: true, null: false
      t.integer :idle_timeout_seconds, null: false, default: 300
      t.text :welcome_text, null: false
      t.boolean :allow_cash, default: true, null: false
      t.boolean :allow_card, default: true, null: false
      t.jsonb :display_settings, default: {}
      t.timestamps
    end
    
    add_index :kiosk_settings, [:tenant_id, :device_id], unique: true, name: 'idx_ks_tenant_device', if_not_exists: true
    add_index :kiosk_settings, :tenant_id, if_not_exists: true
    add_index :kiosk_settings, :device_id, if_not_exists: true
    add_index :kiosk_settings, :is_active, if_not_exists: true
    
    execute "COMMENT ON TABLE kiosk_settings IS 'Настройки киоска точки'"
    
    # Таблица kiosk_sessions (сессии пользователей киоска)
    create_table :kiosk_sessions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :device, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.uuid :session_token, null: false
      t.timestamp :started_at, null: false, default: -> { "NOW()" }
      t.timestamp :ended_at
      t.string :end_reason, limit: 50 # timeout, order_completed, manual_reset, device_offline
      t.integer :orders_created, default: 0, null: false
      t.timestamp :last_activity_at, null: false, default: -> { "NOW()" }
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    
    add_index :kiosk_sessions, :session_token, unique: true, if_not_exists: true
    add_index :kiosk_sessions, :device_id, if_not_exists: true
    add_index :kiosk_sessions, :tenant_id, if_not_exists: true
    add_index :kiosk_sessions, :ended_at, where: "ended_at IS NULL", if_not_exists: true
    add_index :kiosk_sessions, :last_activity_at, if_not_exists: true
    
    execute "COMMENT ON TABLE kiosk_sessions IS 'Сессии пользователей киоска'"
    
    # Таблица kiosk_carts (корзины киоска)
    create_table :kiosk_carts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :device, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.uuid :session_token, null: false
      t.jsonb :items, default: [], null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false, default: 0
      t.timestamp :expires_at, null: false
      t.timestamps
    end
    
    add_index :kiosk_carts, :session_token, unique: true, if_not_exists: true
    add_index :kiosk_carts, :tenant_id, if_not_exists: true
    add_index :kiosk_carts, :device_id, if_not_exists: true
    add_index :kiosk_carts, :expires_at, if_not_exists: true
    
    execute "COMMENT ON TABLE kiosk_carts IS 'Корзины киоска (привязка к сессии)'"
    
    # Включаем RLS
    execute "ALTER TABLE kiosk_settings ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE kiosk_sessions ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE kiosk_carts ENABLE ROW LEVEL SECURITY"
    
    # RLS политики для kiosk_settings
    execute <<-SQL
      CREATE POLICY rls_kiosk_settings_isolation ON kiosk_settings
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
    
    # RLS политики для kiosk_sessions
    execute <<-SQL
      CREATE POLICY rls_kiosk_sessions_isolation ON kiosk_sessions
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
    
    # RLS политики для kiosk_carts
    execute <<-SQL
      CREATE POLICY rls_kiosk_carts_isolation ON kiosk_carts
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
  end
  
  def down
    execute "DROP POLICY IF EXISTS rls_kiosk_carts_isolation ON kiosk_carts"
    execute "DROP POLICY IF EXISTS rls_kiosk_sessions_isolation ON kiosk_sessions"
    execute "DROP POLICY IF EXISTS rls_kiosk_settings_isolation ON kiosk_settings"
    
    drop_table :kiosk_carts, if_exists: true
    drop_table :kiosk_sessions, if_exists: true
    drop_table :kiosk_settings, if_exists: true
  end
end
