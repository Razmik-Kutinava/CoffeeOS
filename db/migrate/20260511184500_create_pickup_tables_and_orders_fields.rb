# frozen_string_literal: true

class CreatePickupTablesAndOrdersFields < ActiveRecord::Migration[8.1]
  def up
    create_table :pickup_display_settings, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :device, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :display_mode, null: false, default: "number", limit: 50
      t.boolean :show_order_items, null: false, default: false
      t.integer :items_visible_count, null: false, default: 10
      t.integer :auto_complete_seconds
      t.boolean :sound_enabled, null: false, default: true
      t.text :welcome_message, default: "Ваш заказ готов!"
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end

    add_index :pickup_display_settings, [:tenant_id, :device_id], unique: true, if_not_exists: true
    add_check_constraint :pickup_display_settings, "display_mode IN ('number', 'name', 'both')", name: "chk_pickup_display_mode"
    add_check_constraint :pickup_display_settings, "items_visible_count BETWEEN 1 AND 20", name: "chk_pickup_items_visible_count"
    add_check_constraint :pickup_display_settings, "auto_complete_seconds IS NULL OR auto_complete_seconds > 0", name: "chk_pickup_auto_complete_seconds"
    add_index :pickup_display_settings, :tenant_id, if_not_exists: true, name: "idx_pickup_display_settings_tenant"
    add_index :pickup_display_settings, :device_id, if_not_exists: true, name: "idx_pickup_display_settings_device"
    add_index :pickup_display_settings, [:tenant_id, :is_active], if_not_exists: true, where: "is_active = TRUE", name: "idx_pickup_display_settings_active"

    create_table :pickup_calls, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :order, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :device, type: :uuid, null: true, foreign_key: { on_delete: :nullify }
      t.references :called_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :call_type, null: false, default: "ready", limit: 50
      t.timestamp :called_at, null: false, default: -> { "NOW()" }
      t.timestamp :acknowledged_at
    end

    add_check_constraint :pickup_calls, "call_type IN ('ready', 'reminder')", name: "chk_pickup_call_type"
    add_index :pickup_calls, :order_id, if_not_exists: true, name: "idx_pickup_calls_order"
    add_index :pickup_calls, [:tenant_id, :called_at], order: { called_at: :desc }, if_not_exists: true, name: "idx_pickup_calls_tenant_created"
    add_index :pickup_calls, [:order_id, :called_at], if_not_exists: true, where: "acknowledged_at IS NULL", name: "idx_pickup_calls_unacknowledged"

    create_table :pickup_events, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :order, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :event_type, null: false, limit: 50
      t.references :device, type: :uuid, null: true, foreign_key: { on_delete: :nullify }
      t.references :created_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.jsonb :meta
      t.timestamp :created_at, null: false, default: -> { "NOW()" }
    end

    add_check_constraint :pickup_events, "event_type IN ('ready', 'called', 'qr_scanned', 'issued', 'timeout', 'not_picked_up')", name: "chk_pickup_event_type"
    add_index :pickup_events, :order_id, if_not_exists: true, name: "idx_pickup_events_order"
    add_index :pickup_events, [:tenant_id, :created_at], order: { created_at: :desc }, if_not_exists: true, name: "idx_pickup_events_tenant_created"
    add_index :pickup_events, :event_type, if_not_exists: true, name: "idx_pickup_events_type"

    add_column :orders, :ready_at, :timestamptz unless column_exists?(:orders, :ready_at)
    add_column :orders, :issued_at, :timestamptz unless column_exists?(:orders, :issued_at)
    add_column :orders, :pickup_method, :string, limit: 50 unless column_exists?(:orders, :pickup_method)

    add_check_constraint :orders, "pickup_method IS NULL OR pickup_method IN ('qr', 'manual', 'auto')", name: "chk_pickup_method" unless check_constraint_exists?(:orders, name: "chk_pickup_method")
    add_index :orders, :ready_at, if_not_exists: true, where: "ready_at IS NOT NULL", name: "idx_orders_ready_at"
    add_index :orders, :issued_at, if_not_exists: true, where: "issued_at IS NOT NULL", name: "idx_orders_issued_at"
  end

  def down
    remove_index :orders, name: "idx_orders_issued_at" if index_exists?(:orders, name: "idx_orders_issued_at")
    remove_index :orders, name: "idx_orders_ready_at" if index_exists?(:orders, name: "idx_orders_ready_at")
    remove_check_constraint :orders, name: "chk_pickup_method" if check_constraint_exists?(:orders, name: "chk_pickup_method")
    remove_column :orders, :pickup_method if column_exists?(:orders, :pickup_method)
    remove_column :orders, :issued_at if column_exists?(:orders, :issued_at)
    remove_column :orders, :ready_at if column_exists?(:orders, :ready_at)

    drop_table :pickup_events, if_exists: true
    drop_table :pickup_calls, if_exists: true
    drop_table :pickup_display_settings, if_exists: true
  end
end
