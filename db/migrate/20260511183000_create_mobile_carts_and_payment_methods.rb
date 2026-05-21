# frozen_string_literal: true

class CreateMobileCartsAndPaymentMethods < ActiveRecord::Migration[8.1]
  def up
    create_table :mobile_payment_methods, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :customer, type: :uuid, null: false, foreign_key: { to_table: :mobile_customers, on_delete: :cascade }
      t.string :payment_type, null: false, default: "card", limit: 20
      t.text :card_token
      t.string :card_masked, limit: 20
      t.string :card_brand, limit: 20
      t.string :card_expires_at, limit: 7
      t.boolean :is_default, null: false, default: false
      t.boolean :is_active, null: false, default: true
      t.timestamp :last_used_at
      t.timestamp :created_at, null: false, default: -> { "NOW()" }
    end

    add_check_constraint :mobile_payment_methods, "payment_type IN ('card', 'sbp', 'ya_pay')", name: "chk_pm_type"
    add_index :mobile_payment_methods, :customer_id, if_not_exists: true, name: "idx_pm_customer"
    add_index :mobile_payment_methods, :customer_id, if_not_exists: true, where: "is_default = TRUE AND is_active = TRUE", name: "idx_pm_default"
    add_index :mobile_payment_methods, [:customer_id, :is_active], if_not_exists: true, where: "is_active = TRUE", name: "idx_pm_active"

    create_table :mobile_carts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :customer, type: :uuid, null: false, foreign_key: { to_table: :mobile_customers, on_delete: :cascade }
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.jsonb :items, null: false, default: []
      t.decimal :total_amount, precision: 10, scale: 2, null: false, default: 0
      t.timestamp :expires_at, null: false, default: -> { "NOW() + INTERVAL '24 hours'" }
      t.timestamps
    end

    add_index :mobile_carts, [:customer_id, :tenant_id], unique: true, if_not_exists: true
    add_check_constraint :mobile_carts, "total_amount >= 0", name: "chk_mobile_cart_total"
    add_index :mobile_carts, :customer_id, if_not_exists: true, name: "idx_mobile_carts_customer"
    add_index :mobile_carts, :tenant_id, if_not_exists: true, name: "idx_mobile_carts_tenant"
    add_index :mobile_carts, :expires_at, if_not_exists: true, name: "idx_mobile_carts_expires"
  end

  def down
    remove_check_constraint :mobile_carts, name: "chk_mobile_cart_total" if check_constraint_exists?(:mobile_carts, name: "chk_mobile_cart_total")
    drop_table :mobile_carts, if_exists: true

    remove_check_constraint :mobile_payment_methods, name: "chk_pm_type" if check_constraint_exists?(:mobile_payment_methods, name: "chk_pm_type")
    drop_table :mobile_payment_methods, if_exists: true
  end
end
