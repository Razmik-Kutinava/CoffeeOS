class CreateStage0Foundation < ActiveRecord::Migration[8.1]
  def up
    # Таблица tenants (точки продаж)
    create_table :tenants, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :address
      t.string :city, limit: 100
      t.string :country, limit: 2, default: 'RU', null: false
      t.string :currency, limit: 3, default: 'RUB', null: false
      t.string :timezone, limit: 50, default: 'Europe/Moscow'
      t.string :type, null: false # sales_point, production_kitchen
      t.string :status, null: false, default: 'active' # active, warning, suspended, blocked, frozen
      t.jsonb :settings, default: {}
      t.timestamps
    end
    
    add_index :tenants, :slug, unique: true, if_not_exists: true
    add_index :tenants, :status, if_not_exists: true
    add_index :tenants, :type, if_not_exists: true
    add_index :tenants, :country, if_not_exists: true
    
    execute "COMMENT ON TABLE tenants IS 'Точки продаж (кофейни)'"
    execute "COMMENT ON COLUMN tenants.slug IS 'URL-friendly идентификатор точки'"
    execute "COMMENT ON COLUMN tenants.settings IS 'Настройки точки: график работы, контакты, etc'"
    
    # Таблица roles (роли)
    create_table :roles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :code, null: false, limit: 50
      t.string :name, null: false, limit: 100
      t.text :description
      t.boolean :is_system, default: false, null: false
      t.timestamps
    end
    
    add_index :roles, :code, unique: true, if_not_exists: true
    
    execute "COMMENT ON TABLE roles IS 'Роли пользователей'"
    execute "COMMENT ON COLUMN roles.code IS 'Уникальный код роли для проверок в коде'"
    execute "COMMENT ON COLUMN roles.is_system IS 'Системная роль, нельзя удалить'"
    
    # Таблица users (пользователи)
    create_table :users, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: true, foreign_key: { on_delete: :nullify }
      t.string :name, null: false
      t.string :email
      t.string :phone, limit: 20
      t.string :password_hash, null: false
      t.string :status, null: false, default: 'active' # active, blocked
      t.timestamp :last_login_at
      t.timestamps
    end
    
    add_index :users, :email, unique: true, where: "email IS NOT NULL", if_not_exists: true
    add_index :users, :phone, unique: true, where: "phone IS NOT NULL", if_not_exists: true
    add_index :users, :tenant_id, if_not_exists: true
    add_index :users, :status, if_not_exists: true
    
    execute "COMMENT ON TABLE users IS 'Пользователи системы (сотрудники кофеен)'"
    
    # Таблица user_roles (связь users ↔ roles)
    create_table :user_roles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :role, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :tenant, type: :uuid, null: true, foreign_key: { on_delete: :cascade }
      t.timestamp :granted_at, default: -> { "NOW()" }
      t.references :granted_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
    end
    
    add_index :user_roles, [:user_id, :role_id, :tenant_id], unique: true, name: 'idx_user_roles_unique', if_not_exists: true
    add_index :user_roles, :user_id, if_not_exists: true
    add_index :user_roles, :role_id, if_not_exists: true
    add_index :user_roles, :tenant_id, if_not_exists: true
    
    execute "COMMENT ON TABLE user_roles IS 'Связь пользователей и ролей (many-to-many)'"
    
    # Таблица sessions (сессии пользователей)
    create_table :sessions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :tenant, type: :uuid, null: true, foreign_key: { on_delete: :cascade }
      t.string :token, null: false, limit: 255
      t.timestamp :expires_at, null: false
      t.timestamp :revoked_at
      t.string :ip_address, limit: 45
      t.string :user_agent, limit: 500
      t.timestamps
    end
    
    add_index :sessions, :token, unique: true, if_not_exists: true
    add_index :sessions, :user_id, if_not_exists: true
    add_index :sessions, :tenant_id, if_not_exists: true
    add_index :sessions, :expires_at, if_not_exists: true
    
    execute "COMMENT ON TABLE sessions IS 'Активные сессии пользователей'"
    
    # Таблица ingredients (ингредиенты)
    create_table :ingredients, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :unit, null: false, limit: 10 # g, ml, pcs
      t.boolean :is_active, default: true, null: false
      t.text :description
      t.timestamps
    end
    
    add_index :ingredients, :name, if_not_exists: true
    add_index :ingredients, :is_active, if_not_exists: true
    
    execute "COMMENT ON TABLE ingredients IS 'Глобальный справочник ингредиентов (управляет УК)'"
    
    # Таблица feature_flags (флаги фич)
    create_table :feature_flags, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :module, null: false, limit: 100
      t.boolean :enabled, default: false, null: false
      t.references :enabled_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamp :enabled_at
      t.timestamps
    end
    
    add_index :feature_flags, [:tenant_id, :module], unique: true, if_not_exists: true
    add_index :feature_flags, :enabled, if_not_exists: true
    
    execute "COMMENT ON TABLE feature_flags IS 'Флаги для A/B тестов и постепенного раската фич'"
    
    # Включаем RLS на таблицах с tenant_id
    execute "ALTER TABLE users ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE sessions ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY"
    
    # RLS политики для users
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
    
    # RLS политики для user_roles
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
    
    # RLS политики для sessions
    execute <<-SQL
      CREATE POLICY rls_sessions_isolation ON sessions
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
        )
    SQL
    
    # RLS политики для feature_flags
    execute <<-SQL
      CREATE POLICY rls_feature_flags_isolation ON feature_flags
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
  end
  
  def down
    execute "DROP POLICY IF EXISTS rls_feature_flags_isolation ON feature_flags"
    execute "DROP POLICY IF EXISTS rls_sessions_isolation ON sessions"
    execute "DROP POLICY IF EXISTS rls_user_roles_isolation ON user_roles"
    execute "DROP POLICY IF EXISTS rls_users_isolation ON users"
    
    drop_table :feature_flags, if_exists: true
    drop_table :ingredients, if_exists: true
    drop_table :sessions, if_exists: true
    drop_table :user_roles, if_exists: true
    drop_table :users, if_exists: true
    drop_table :roles, if_exists: true
    drop_table :tenants, if_exists: true
  end
end
