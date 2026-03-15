class CreateStage4Devices < ActiveRecord::Migration[8.1]
  def up
    # Таблица devices (устройства)
    create_table :devices, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :device_type, null: false, limit: 50 # barista_tablet, tv_board, kiosk, smart_locker
      t.string :name, null: false, limit: 255
      t.string :device_token, limit: 255
      t.timestamp :token_expires_at
      t.boolean :is_active, default: true, null: false
      t.timestamp :last_seen_at
      t.jsonb :metadata, default: {}
      t.references :registered_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    
    add_index :devices, :tenant_id, if_not_exists: true
    add_index :devices, :device_type, if_not_exists: true
    add_index :devices, :device_token, unique: true, where: "device_token IS NOT NULL", if_not_exists: true
    add_index :devices, :is_active, if_not_exists: true
    add_index :devices, :last_seen_at, if_not_exists: true
    
    execute "COMMENT ON TABLE devices IS 'Зарегистрированные устройства (киоски, планшеты баристы, ТВ)'"
    
    # Таблица device_sessions (сессии устройств)
    create_table :device_sessions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :device, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :connection_type, null: false, limit: 20 # websocket, http, grpc
      t.string :connection_id, limit: 255
      t.timestamp :connected_at, null: false, default: -> { "NOW()" }
      t.timestamp :disconnected_at
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    
    add_index :device_sessions, :device_id, if_not_exists: true
    add_index :device_sessions, :tenant_id, if_not_exists: true
    add_index :device_sessions, :connected_at, if_not_exists: true
    add_index :device_sessions, :disconnected_at, where: "disconnected_at IS NULL", if_not_exists: true
    
    execute "COMMENT ON TABLE device_sessions IS 'Активные сессии устройств'"
    
    # Таблица tv_board_settings (настройки ТВ-борда)
    create_table :tv_board_settings, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.integer :show_order_count, null: false, default: 10
      t.integer :display_seconds_ready, null: false, default: 60
      t.string :theme, null: false, default: 'dark', limit: 20 # dark, light, brand
      t.jsonb :custom_css, default: {}
      t.references :updated_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    
    add_index :tv_board_settings, :tenant_id, unique: true, if_not_exists: true
    
    execute "COMMENT ON TABLE tv_board_settings IS 'Настройки ТВ-борда для точки'"
    
    # Включаем RLS
    execute "ALTER TABLE devices ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE device_sessions ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE tv_board_settings ENABLE ROW LEVEL SECURITY"
    
    # RLS политики для devices
    execute <<-SQL
      CREATE POLICY rls_devices_isolation ON devices
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
    
    # RLS политики для device_sessions
    execute <<-SQL
      CREATE POLICY rls_device_sessions_isolation ON device_sessions
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
    
    # RLS политики для tv_board_settings
    execute <<-SQL
      CREATE POLICY rls_tv_board_settings_isolation ON tv_board_settings
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
    
    # Добавляем foreign key для order_status_logs.device_id -> devices.id
    # (таблица order_status_logs создана в миграции этапа 1, но foreign key не был добавлен)
    execute <<-SQL
      ALTER TABLE order_status_logs
      ADD CONSTRAINT fk_order_status_logs_device
      FOREIGN KEY (device_id)
      REFERENCES devices(id)
      ON DELETE SET NULL;
    SQL
  end
  
  def down
    execute "DROP POLICY IF EXISTS rls_tv_board_settings_isolation ON tv_board_settings"
    execute "DROP POLICY IF EXISTS rls_device_sessions_isolation ON device_sessions"
    execute "DROP POLICY IF EXISTS rls_devices_isolation ON devices"
    
    # Удаляем foreign key перед удалением таблицы
    execute "ALTER TABLE order_status_logs DROP CONSTRAINT IF EXISTS fk_order_status_logs_device"
    
    drop_table :tv_board_settings, if_exists: true
    drop_table :device_sessions, if_exists: true
    drop_table :devices, if_exists: true
  end
end
