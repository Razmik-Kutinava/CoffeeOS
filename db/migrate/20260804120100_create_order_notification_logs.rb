# frozen_string_literal: true

# #39 — история платных каналов каскада (Telegram / SMS).
# Откат: drop_table :order_notification_logs
class CreateOrderNotificationLogs < ActiveRecord::Migration[8.0]
  def up
    create_table :order_notification_logs, id: :uuid, default: -> { "gen_random_uuid()" },
      comment: "Лог каскада уведомлений «Заказ готов» (#39)" do |t|
      t.uuid :order_id, null: false
      t.uuid :tenant_id, null: false
      t.string :channel, limit: 32, null: false
      t.string :status, limit: 32, null: false, default: "pending"
      t.text :error_message
      t.jsonb :payload, null: false, default: {}
      t.timestamps
    end

    add_index :order_notification_logs, :order_id, name: "idx_order_notification_logs_order"
    add_index :order_notification_logs, [:tenant_id, :created_at],
      name: "idx_order_notification_logs_tenant_created", order: { created_at: :desc }
    add_index :order_notification_logs, [:order_id, :channel, :created_at],
      name: "idx_order_notification_logs_order_channel"

    add_foreign_key :order_notification_logs, :orders
    add_foreign_key :order_notification_logs, :tenants

    execute <<-SQL.squish
      ALTER TABLE order_notification_logs
        ADD CONSTRAINT chk_order_notification_logs_channel
        CHECK (channel IN ('telegram', 'sms'));
    SQL

    execute <<-SQL.squish
      ALTER TABLE order_notification_logs
        ADD CONSTRAINT chk_order_notification_logs_status
        CHECK (status IN ('pending', 'sent', 'failed', 'skipped'));
    SQL

    execute "ALTER TABLE order_notification_logs ENABLE ROW LEVEL SECURITY"

    execute <<-SQL
      CREATE POLICY rls_order_notification_logs_isolation ON order_notification_logs
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
        WITH CHECK (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'franchise_manager')
          )
        )
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS rls_order_notification_logs_isolation ON order_notification_logs"
    drop_table :order_notification_logs, if_exists: true
  end
end
