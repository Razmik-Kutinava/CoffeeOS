class CreateStage7Mobile < ActiveRecord::Migration[8.1]
  def up
    # Таблица mobile_customers (клиенты мобильного приложения)
    create_table :mobile_customers, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :phone, null: false, limit: 20
      t.string :email, limit: 255
      t.string :first_name, limit: 100
      t.string :last_name, limit: 100
      t.boolean :is_active, default: true, null: false
      t.boolean :push_enabled, default: false, null: false
      t.string :push_token, limit: 255
      t.timestamp :last_login_at
      t.timestamps
    end
    
    add_index :mobile_customers, :phone, unique: true, if_not_exists: true
    add_index :mobile_customers, :email, unique: true, where: "email IS NOT NULL", if_not_exists: true
    add_index :mobile_customers, :is_active, if_not_exists: true
    
    execute "COMMENT ON TABLE mobile_customers IS 'Клиенты мобильного приложения'"
    
    # Таблица mobile_sessions (сессии мобильного приложения)
    create_table :mobile_sessions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :customer, type: :uuid, null: false, foreign_key: { to_table: :mobile_customers, on_delete: :cascade }
      t.string :refresh_token, null: false, limit: 255
      t.boolean :is_active, default: true, null: false
      t.timestamp :expires_at, null: false
      t.timestamp :last_used_at
      t.string :device_id, limit: 255
      t.string :device_type, limit: 50 # ios, android
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    
    add_index :mobile_sessions, :refresh_token, unique: true, if_not_exists: true
    add_index :mobile_sessions, :customer_id, if_not_exists: true
    add_index :mobile_sessions, :expires_at, if_not_exists: true
    add_index :mobile_sessions, :is_active, if_not_exists: true
    
    execute "COMMENT ON TABLE mobile_sessions IS 'Сессии мобильного приложения'"
    
    # Таблица mobile_otp_codes (OTP коды для авторизации)
    create_table :mobile_otp_codes, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :phone, null: false, limit: 20
      t.string :code, null: false, limit: 6
      t.boolean :is_used, default: false, null: false
      t.integer :attempts, default: 0, null: false
      t.timestamp :expires_at, null: false
      t.timestamps
    end
    
    add_index :mobile_otp_codes, :phone, if_not_exists: true
    add_index :mobile_otp_codes, :code, if_not_exists: true
    add_index :mobile_otp_codes, :expires_at, if_not_exists: true
    add_index :mobile_otp_codes, :is_used, if_not_exists: true
    
    execute "COMMENT ON TABLE mobile_otp_codes IS 'OTP коды для авторизации в мобильном приложении'"
    
    # Добавляем foreign key для orders.customer_id -> mobile_customers.id
    # (таблица orders создана в миграции этапа 1, но foreign key не был добавлен)
    execute <<-SQL
      ALTER TABLE orders
      ADD CONSTRAINT fk_orders_customer
      FOREIGN KEY (customer_id)
      REFERENCES mobile_customers(id)
      ON DELETE SET NULL;
    SQL
    
    # RLS не нужен для mobile_customers, mobile_sessions, mobile_otp_codes
    # т.к. они не привязаны к tenant_id напрямую
  end
  
  def down
    # Удаляем foreign key перед удалением таблицы
    execute "ALTER TABLE orders DROP CONSTRAINT IF EXISTS fk_orders_customer"
    
    drop_table :mobile_otp_codes, if_exists: true
    drop_table :mobile_sessions, if_exists: true
    drop_table :mobile_customers, if_exists: true
  end
end
