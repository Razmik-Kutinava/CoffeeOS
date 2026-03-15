class CreateStage1Orders < ActiveRecord::Migration[8.1]
  def up
    # ENUM для статусов заказа
    execute <<-SQL
      CREATE TYPE order_status AS ENUM (
        'pending_payment',
        'accepted',
        'preparing',
        'ready',
        'issued',
        'closed',
        'cancelled'
      )
    SQL
    
    # ENUM для источника заказа
    execute <<-SQL
      CREATE TYPE order_source AS ENUM (
        'kiosk',
        'app',
        'manual',
        'mobile'
      )
    SQL
    
    # Таблица order_cancel_reasons (справочник причин отмены)
    create_table :order_cancel_reasons, id: false do |t|
      t.string :code, primary_key: true, limit: 50
      t.string :name, null: false, limit: 100
      t.text :description
      t.integer :sort_order, default: 0
      t.boolean :is_active, default: true, null: false
      t.timestamps
    end
    
    execute "COMMENT ON TABLE order_cancel_reasons IS 'Справочник причин отмены заказа'"
    
    # Таблица orders (заказы)
    create_table :orders, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :order_number, null: false, limit: 20
      t.bigserial :order_sequence
      t.column :source, :order_source, null: false
      t.references :customer, type: :uuid, null: true # foreign_key будет добавлен в миграции после создания mobile_customers
      t.string :customer_name, limit: 255
      t.column :status, :order_status, null: false, default: 'pending_payment'
      t.string :cancel_reason_code, limit: 50
      t.text :cancel_reason
      t.string :cancel_stage, limit: 50
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.decimal :discount_amount, precision: 10, scale: 2, null: false, default: 0
      t.decimal :final_amount, precision: 10, scale: 2, null: false
      t.uuid :promo_code_id
      t.string :locker_cell, limit: 10
      t.uuid :qr_token
      t.timestamp :qr_expires_at
      t.timestamps
    end
    
    add_index :orders, [:tenant_id, :order_number], unique: true, name: 'idx_orders_tenant_number', if_not_exists: true
    add_index :orders, :tenant_id, if_not_exists: true
    add_index :orders, :status, if_not_exists: true
    add_index :orders, [:tenant_id, :status], if_not_exists: true
    add_index :orders, [:tenant_id, :created_at], order: { created_at: :desc }, if_not_exists: true
    add_index :orders, :order_number, if_not_exists: true
    add_index :orders, :customer_id, if_not_exists: true
    add_index :orders, :qr_token, where: "qr_token IS NOT NULL", if_not_exists: true
    
    add_foreign_key :orders, :order_cancel_reasons, column: :cancel_reason_code, primary_key: :code, on_delete: :nullify
    
    execute <<-SQL
      ALTER TABLE orders
      ADD CONSTRAINT chk_order_amounts CHECK (
        total_amount > 0 AND
        discount_amount >= 0 AND
        final_amount >= 0 AND
        final_amount = total_amount - discount_amount
      )
    SQL
    
    execute "COMMENT ON TABLE orders IS 'Заказы клиентов'"
    execute "COMMENT ON COLUMN orders.order_number IS 'Читаемый номер заказа #YYYYMM-#### (уникален в пределах тенанта)'"
    execute "COMMENT ON COLUMN orders.order_sequence IS 'Автоинкремент для генерации номера заказа'"
    
    # Таблица order_items (позиции заказа)
    create_table :order_items, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :order, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :product, type: :uuid, null: false # foreign_key будет добавлен в миграции после создания products
      t.string :product_name, null: false, limit: 255
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :total_price, precision: 10, scale: 2, null: false
      t.jsonb :modifier_options, default: {}
      t.timestamps
    end
    
    add_index :order_items, :order_id, if_not_exists: true
    add_index :order_items, :product_id, if_not_exists: true
    add_index :order_items, :modifier_options, using: :gin, if_not_exists: true
    
    execute <<-SQL
      ALTER TABLE order_items
      ADD CONSTRAINT chk_order_item_quantity CHECK (quantity > 0),
      ADD CONSTRAINT chk_order_item_prices CHECK (
        unit_price > 0 AND
        total_price = unit_price * quantity
      )
    SQL
    
    execute "COMMENT ON TABLE order_items IS 'Позиции заказа (продукты + модификаторы)'"
    execute "COMMENT ON COLUMN order_items.product_name IS 'Снапшот названия на момент заказа'"
    execute "COMMENT ON COLUMN order_items.modifier_options IS 'JSON: {\"milk_type\": \"uuid\", \"syrup\": \"uuid\"}'"
    
    # Таблица order_status_log (история статусов)
    create_table :order_status_logs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :order, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.column :status_from, :order_status
      t.column :status_to, :order_status, null: false
      t.references :changed_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :device, type: :uuid, null: true # foreign_key будет добавлен в миграции после создания devices
      t.string :source, limit: 50, default: 'barista'
      t.text :comment
      t.timestamps
    end
    
    add_index :order_status_logs, :order_id, if_not_exists: true
    add_index :order_status_logs, :changed_by_id, if_not_exists: true
    add_index :order_status_logs, :created_at, if_not_exists: true
    
    execute "COMMENT ON TABLE order_status_logs IS 'История изменений статуса заказа'"
    
    # Включаем RLS
    execute "ALTER TABLE orders ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE order_items ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE order_status_logs ENABLE ROW LEVEL SECURITY"
    
    # RLS политики для orders
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
    
    # RLS политики для order_items (через order.tenant_id)
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
    
    # RLS политики для order_status_logs (через order.tenant_id)
    execute <<-SQL
      CREATE POLICY rls_order_status_logs_isolation ON order_status_logs
        FOR ALL
        USING (
          EXISTS (
            SELECT 1 FROM orders o
            WHERE o.id = order_status_logs.order_id
            AND o.tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          )
        )
    SQL
  end
  
  def down
    execute "DROP POLICY IF EXISTS rls_order_status_logs_isolation ON order_status_logs"
    execute "DROP POLICY IF EXISTS rls_order_items_isolation ON order_items"
    execute "DROP POLICY IF EXISTS rls_orders_isolation ON orders"
    
    drop_table :order_status_logs, if_exists: true
    drop_table :order_items, if_exists: true
    drop_table :orders, if_exists: true
    drop_table :order_cancel_reasons, if_exists: true
    
    execute "DROP TYPE IF EXISTS order_source"
    execute "DROP TYPE IF EXISTS order_status"
  end
end
