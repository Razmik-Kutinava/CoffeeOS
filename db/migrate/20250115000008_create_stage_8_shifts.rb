class CreateStage8Shifts < ActiveRecord::Migration[8.1]
  def up
    # ENUM для статусов смены
    execute <<-SQL
      CREATE TYPE shift_status AS ENUM (
        'open',
        'closed',
        'cancelled'
      )
    SQL
    
    # Таблица shifts (смены)
    create_table :shifts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :opened_by, type: :uuid, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :closed_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.column :status, :shift_status, null: false, default: 'open'
      t.timestamp :opened_at, null: false, default: -> { "NOW()" }
      t.timestamp :closed_at
      t.decimal :opening_cash, precision: 10, scale: 2, null: false, default: 0
      t.decimal :closing_cash, precision: 10, scale: 2
      t.decimal :total_sales, precision: 10, scale: 2
      t.decimal :total_refunds, precision: 10, scale: 2
      t.decimal :expected_cash, precision: 10, scale: 2
      t.decimal :cash_difference, precision: 10, scale: 2
      t.text :note
      t.timestamps
    end
    
    add_index :shifts, :tenant_id, if_not_exists: true
    add_index :shifts, :status, if_not_exists: true
    add_index :shifts, :opened_at, order: { opened_at: :desc }, if_not_exists: true
    add_index :shifts, [:tenant_id, :status], where: "status = 'open'", unique: true, name: 'idx_one_open_shift_per_tenant', if_not_exists: true
    
    execute "COMMENT ON TABLE shifts IS 'Смены (расширенная версия cash_shifts)'"
    
    # Таблица shift_staffs (персонал в смене)
    create_table :shift_staffs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :shift, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, type: :uuid, null: false, foreign_key: { on_delete: :restrict }
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :role_in_shift, null: false, limit: 50 # barista, shift_manager
      t.timestamp :checked_in_at, null: false, default: -> { "NOW()" }
      t.timestamp :checked_out_at
      t.timestamps
    end
    
    add_index :shift_staffs, [:shift_id, :user_id], unique: true, name: 'idx_shift_staffs_unique', if_not_exists: true
    add_index :shift_staffs, :shift_id, if_not_exists: true
    add_index :shift_staffs, :user_id, if_not_exists: true
    add_index :shift_staffs, :tenant_id, if_not_exists: true
    add_index :shift_staffs, :checked_out_at, where: "checked_out_at IS NULL", if_not_exists: true
    
    execute "COMMENT ON TABLE shift_staffs IS 'Персонал в смене'"
    
    # Таблица shift_cash_operations (кассовые операции в смене)
    create_table :shift_cash_operations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :shift, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :operation_type, null: false, limit: 50 # deposit, withdrawal, collection
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.text :note
      t.references :created_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    
    add_index :shift_cash_operations, :shift_id, if_not_exists: true
    add_index :shift_cash_operations, :tenant_id, if_not_exists: true
    add_index :shift_cash_operations, :operation_type, if_not_exists: true
    add_index :shift_cash_operations, :created_at, order: { created_at: :desc }, if_not_exists: true
    
    execute "COMMENT ON TABLE shift_cash_operations IS 'Кассовые операции в смене (внесение/изъятие наличных)'"
    
    # Включаем RLS
    execute "ALTER TABLE shifts ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE shift_staffs ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE shift_cash_operations ENABLE ROW LEVEL SECURITY"
    
    # RLS политики для shifts
    execute <<-SQL
      CREATE POLICY rls_shifts_isolation ON shifts
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
    
    # RLS политики для shift_staffs
    execute <<-SQL
      CREATE POLICY rls_shift_staffs_isolation ON shift_staffs
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
    
    # RLS политики для shift_cash_operations
    execute <<-SQL
      CREATE POLICY rls_shift_cash_operations_isolation ON shift_cash_operations
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
  end
  
  def down
    execute "DROP POLICY IF EXISTS rls_shift_cash_operations_isolation ON shift_cash_operations"
    execute "DROP POLICY IF EXISTS rls_shift_staffs_isolation ON shift_staffs"
    execute "DROP POLICY IF EXISTS rls_shifts_isolation ON shifts"
    
    drop_table :shift_cash_operations, if_exists: true
    drop_table :shift_staffs, if_exists: true
    drop_table :shifts, if_exists: true
    
    execute "DROP TYPE IF EXISTS shift_status"
  end
end
