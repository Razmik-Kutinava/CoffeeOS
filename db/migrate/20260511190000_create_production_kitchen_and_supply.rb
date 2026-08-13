# frozen_string_literal: true

class CreateProductionKitchenAndSupply < ActiveRecord::Migration[8.1]
  def up
    add_column :ingredients, :is_semifinished, :boolean, null: false, default: false unless column_exists?(:ingredients, :is_semifinished)
    add_column :ingredients, :shelf_life_hours, :integer unless column_exists?(:ingredients, :shelf_life_hours)
    add_column :ingredients, :storage_temp, :string, limit: 50 unless column_exists?(:ingredients, :storage_temp)
    add_column :ingredients, :production_unit, :string, limit: 20 unless column_exists?(:ingredients, :production_unit)

    add_check_constraint :ingredients, "storage_temp IS NULL OR storage_temp IN ('room', 'refrigerated', 'frozen')", name: "chk_ingredient_storage_temp" unless check_constraint_exists?(:ingredients, name: "chk_ingredient_storage_temp")

    add_index :ingredients, :is_semifinished, if_not_exists: true, where: "is_semifinished = TRUE", name: "idx_ingredients_semifinished"
    add_index :ingredients, :storage_temp, if_not_exists: true, name: "idx_ingredients_storage_temp"

    create_table :production_recipes, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :semifinished_id, null: false
      t.uuid :ingredient_id, null: false
      t.decimal :quantity, precision: 10, scale: 3, null: false
      t.string :unit_override, limit: 20
      t.text :note
      t.timestamps
    end

    add_foreign_key :production_recipes, :ingredients, column: :semifinished_id, on_delete: :cascade
    add_foreign_key :production_recipes, :ingredients, column: :ingredient_id, on_delete: :cascade
    add_index :production_recipes, [ :semifinished_id, :ingredient_id ], unique: true, name: "idx_production_recipes_semifinished_ingredient"
    add_index :production_recipes, :semifinished_id, name: "idx_production_recipes_semifinished"
    add_index :production_recipes, :ingredient_id, name: "idx_production_recipes_ingredient"
    add_check_constraint :production_recipes, "quantity > 0", name: "chk_production_recipe_quantity"
    add_check_constraint :production_recipes, "semifinished_id <> ingredient_id", name: "chk_production_recipe_not_self"

    create_table :production_batches, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :semifinished, type: :uuid, null: false, foreign_key: { to_table: :ingredients, on_delete: :cascade }, index: false
      t.decimal :quantity, precision: 10, scale: 3, null: false
      t.string :status, limit: 50, null: false, default: "planned"
      t.datetime :planned_at, precision: nil, null: false, default: -> { "NOW()" }
      t.datetime :started_at, precision: nil
      t.datetime :completed_at, precision: nil
      t.datetime :expires_at, precision: nil
      t.references :produced_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.text :note
      t.timestamps
    end

    add_check_constraint :production_batches, "quantity > 0", name: "chk_batch_quantity"
    add_check_constraint :production_batches, "status IN ('planned', 'in_progress', 'completed', 'cancelled')", name: "chk_batch_status"
    add_index :production_batches, [ :tenant_id, :status ], name: "idx_production_batches_tenant_status"
    add_index :production_batches, :semifinished_id, name: "idx_production_batches_semifinished"
    add_index :production_batches, :planned_at, order: { planned_at: :desc }, name: "idx_production_batches_planned_at"
    add_index :production_batches, :expires_at, where: "expires_at IS NOT NULL", name: "idx_production_batches_expires"

    create_table :supply_orders, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :from_tenant_id, null: false
      t.uuid :to_tenant_id, null: false
      t.string :status, limit: 50, null: false, default: "pending"
      t.references :requested_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :confirmed_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :shipped_at, precision: nil
      t.datetime :received_at, precision: nil
      t.text :note
      t.timestamps
    end

    add_foreign_key :supply_orders, :tenants, column: :from_tenant_id, on_delete: :cascade
    add_foreign_key :supply_orders, :tenants, column: :to_tenant_id, on_delete: :cascade
    add_check_constraint :supply_orders, "from_tenant_id <> to_tenant_id", name: "chk_supply_order_tenants"
    add_check_constraint :supply_orders, "status IN ('pending', 'confirmed', 'shipped', 'received', 'cancelled')", name: "chk_supply_order_status"
    add_index :supply_orders, [ :from_tenant_id, :status ], name: "idx_supply_orders_from_tenant_status"
    add_index :supply_orders, [ :to_tenant_id, :status ], name: "idx_supply_orders_to_tenant_status"
    add_index :supply_orders, :created_at, order: { created_at: :desc }, name: "idx_supply_orders_created_at"

    create_table :supply_order_items, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :supply_order, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :ingredient, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :quantity_requested, precision: 10, scale: 3, null: false
      t.decimal :quantity_shipped, precision: 10, scale: 3
      t.decimal :unit_cost, precision: 10, scale: 2
      t.text :note
    end

    add_index :supply_order_items, [ :supply_order_id, :ingredient_id ], unique: true, name: "idx_supply_order_items_order_ingredient"
    add_index :supply_order_items, :supply_order_id, name: "idx_supply_order_items_supply_order"
    add_index :supply_order_items, :ingredient_id, name: "idx_supply_order_items_ingredient"
    add_check_constraint :supply_order_items, "quantity_requested > 0", name: "chk_supply_item_requested"
    add_check_constraint :supply_order_items, "quantity_shipped IS NULL OR quantity_shipped >= 0", name: "chk_supply_item_shipped"
  end

  def down
    drop_table :supply_order_items, if_exists: true
    drop_table :supply_orders, if_exists: true
    drop_table :production_batches, if_exists: true
    drop_table :production_recipes, if_exists: true

    remove_index :ingredients, name: "idx_ingredients_storage_temp" if index_exists?(:ingredients, name: "idx_ingredients_storage_temp")
    remove_index :ingredients, name: "idx_ingredients_semifinished" if index_exists?(:ingredients, name: "idx_ingredients_semifinished")
    remove_check_constraint :ingredients, name: "chk_ingredient_storage_temp" if check_constraint_exists?(:ingredients, name: "chk_ingredient_storage_temp")

    remove_column :ingredients, :production_unit if column_exists?(:ingredients, :production_unit)
    remove_column :ingredients, :storage_temp if column_exists?(:ingredients, :storage_temp)
    remove_column :ingredients, :shelf_life_hours if column_exists?(:ingredients, :shelf_life_hours)
    remove_column :ingredients, :is_semifinished if column_exists?(:ingredients, :is_semifinished)
  end
end
