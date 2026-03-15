class CreateStage2Payments < ActiveRecord::Migration[8.1]
  def up
    # ENUM для методов оплаты
    execute <<-SQL
      CREATE TYPE payment_method AS ENUM (
        'card',
        'cash',
        'sbp',
        'apple_pay',
        'google_pay',
        'internal_balance',
        'mixed'
      )
    SQL
    
    # ENUM для статусов платежа
    execute <<-SQL
      CREATE TYPE payment_status AS ENUM (
        'pending',
        'processing',
        'succeeded',
        'failed',
        'refunded',
        'partially_refunded',
        'requires_review'
      )
    SQL
    
    # Таблица payments (платежи)
    create_table :payments, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :order, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.column :method, :payment_method, null: false
      t.column :status, :payment_status, null: false, default: 'pending'
      t.string :provider, null: false, limit: 50 # yookassa, sberbank, etc
      t.string :provider_payment_id, limit: 255
      t.jsonb :provider_data, default: {}
      t.timestamp :paid_at
      t.timestamps
    end
    
    add_index :payments, :tenant_id, if_not_exists: true
    add_index :payments, :order_id, if_not_exists: true
    add_index :payments, :status, if_not_exists: true
    add_index :payments, :provider_payment_id, where: "provider_payment_id IS NOT NULL", if_not_exists: true
    add_index :payments, [:tenant_id, :status], if_not_exists: true
    
    execute "COMMENT ON TABLE payments IS 'Платежи по заказам'"
    
    # Таблица payment_status_logs (история статусов платежей)
    create_table :payment_status_logs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :payment, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.column :status_from, :payment_status
      t.column :status_to, :payment_status, null: false
      t.string :source, null: false, limit: 50 # callback, polling, manual
      t.jsonb :provider_response, default: {}
      t.text :note
      t.timestamps
    end
    
    add_index :payment_status_logs, :payment_id, if_not_exists: true
    add_index :payment_status_logs, :created_at, if_not_exists: true
    
    execute "COMMENT ON TABLE payment_status_logs IS 'История статусов платежей'"
    
    # Таблица payment_polling_attempts (попытки опроса статуса)
    create_table :payment_polling_attempts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :payment, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.integer :attempt_number, null: false
      t.column :status, :payment_status
      t.jsonb :provider_response
      t.boolean :success, default: false
      t.text :error_message
      t.timestamps
    end
    
    add_index :payment_polling_attempts, :payment_id, if_not_exists: true
    add_index :payment_polling_attempts, :created_at, if_not_exists: true
    
    execute "COMMENT ON TABLE payment_polling_attempts IS 'Попытки опроса статуса платежа у провайдера'"
    
    # Таблица refunds (возвраты)
    create_table :refunds, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :payment, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :order, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: 'pending' # pending, succeeded, failed
      t.text :reason, null: false
      t.references :initiated_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :provider_refund_id, limit: 255
      t.jsonb :provider_data, default: {}
      t.timestamps
    end
    
    add_index :refunds, :tenant_id, if_not_exists: true
    add_index :refunds, :payment_id, if_not_exists: true
    add_index :refunds, :order_id, if_not_exists: true
    add_index :refunds, :status, if_not_exists: true
    add_index :refunds, :provider_refund_id, where: "provider_refund_id IS NOT NULL", if_not_exists: true
    
    execute "COMMENT ON TABLE refunds IS 'Возвраты средств'"
    
    # Таблица fiscal_receipts (фискальные чеки)
    create_table :fiscal_receipts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :order, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :payment, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :refund, type: :uuid, null: true, foreign_key: { on_delete: :cascade }
      t.string :type, null: false, limit: 20 # payment, refund
      t.string :status, null: false, default: 'pending' # pending, sent, confirmed, failed
      t.string :ofd_provider, null: false, limit: 50
      t.string :ofd_receipt_id, limit: 255
      t.jsonb :receipt_data, null: false
      t.timestamp :sent_at
      t.timestamp :confirmed_at
      t.text :error_message
      t.timestamps
    end
    
    add_index :fiscal_receipts, :tenant_id, if_not_exists: true
    add_index :fiscal_receipts, :order_id, if_not_exists: true
    add_index :fiscal_receipts, :payment_id, if_not_exists: true
    add_index :fiscal_receipts, :refund_id, if_not_exists: true
    add_index :fiscal_receipts, :status, if_not_exists: true
    add_index :fiscal_receipts, :ofd_receipt_id, where: "ofd_receipt_id IS NOT NULL", if_not_exists: true
    
    execute "COMMENT ON TABLE fiscal_receipts IS 'Фискальные чеки (ОФД)'"
    
    # Таблица cash_shifts (кассовые смены)
    create_table :cash_shifts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :opened_by, type: :uuid, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :closed_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :status, null: false, default: 'open' # open, closed
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
    
    add_index :cash_shifts, :tenant_id, if_not_exists: true
    add_index :cash_shifts, :status, if_not_exists: true
    add_index :cash_shifts, :opened_at, order: { opened_at: :desc }, if_not_exists: true
, if_not_exists: true, if_not_exists: true
    add_index :cash_shifts, [:tenant_id, :status], where: "status = 'open'", unique: true, name: 'idx_one_open_shift_per_tenant'
    
    execute "COMMENT ON TABLE cash_shifts IS 'Кассовые смены'"
    
    # Включаем RLS
    execute "ALTER TABLE payments ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE payment_status_logs ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE payment_polling_attempts ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE refunds ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE fiscal_receipts ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE cash_shifts ENABLE ROW LEVEL SECURITY"
    
    # RLS политики для payments
    execute <<-SQL
      CREATE POLICY rls_payments_isolation ON payments
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
    
    # RLS политики для payment_status_logs (через payment.tenant_id)
    execute <<-SQL
      CREATE POLICY rls_payment_status_logs_isolation ON payment_status_logs
        FOR ALL
        USING (
          EXISTS (
            SELECT 1 FROM payments p
            WHERE p.id = payment_status_logs.payment_id
            AND p.tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          )
        )
    SQL
    
    # RLS политики для payment_polling_attempts (через payment.tenant_id)
    execute <<-SQL
      CREATE POLICY rls_payment_polling_attempts_isolation ON payment_polling_attempts
        FOR ALL
        USING (
          EXISTS (
            SELECT 1 FROM payments p
            WHERE p.id = payment_polling_attempts.payment_id
            AND p.tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          )
        )
    SQL
    
    # RLS политики для refunds
    execute <<-SQL
      CREATE POLICY rls_refunds_isolation ON refunds
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
    
    # RLS политики для fiscal_receipts
    execute <<-SQL
      CREATE POLICY rls_fiscal_receipts_isolation ON fiscal_receipts
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
    
    # RLS политики для cash_shifts
    execute <<-SQL
      CREATE POLICY rls_cash_shifts_isolation ON cash_shifts
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
  end
  
  def down
    execute "DROP POLICY IF EXISTS rls_cash_shifts_isolation ON cash_shifts"
    execute "DROP POLICY IF EXISTS rls_fiscal_receipts_isolation ON fiscal_receipts"
    execute "DROP POLICY IF EXISTS rls_refunds_isolation ON refunds"
    execute "DROP POLICY IF EXISTS rls_payment_polling_attempts_isolation ON payment_polling_attempts"
    execute "DROP POLICY IF EXISTS rls_payment_status_logs_isolation ON payment_status_logs"
    execute "DROP POLICY IF EXISTS rls_payments_isolation ON payments"
    
    drop_table :cash_shifts, if_exists: true
    drop_table :fiscal_receipts, if_exists: true
    drop_table :refunds, if_exists: true
    drop_table :payment_polling_attempts, if_exists: true
    drop_table :payment_status_logs, if_exists: true
    drop_table :payments, if_exists: true
    
    execute "DROP TYPE IF EXISTS payment_status"
    execute "DROP TYPE IF EXISTS payment_method"
  end
end
