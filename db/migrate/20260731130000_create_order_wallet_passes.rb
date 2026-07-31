# frozen_string_literal: true

# #35 B3 — метаданные Apple Wallet pass на заказ.
# Откат: drop_table :order_wallet_passes
class CreateOrderWalletPasses < ActiveRecord::Migration[8.0]
  def change
    create_table :order_wallet_passes, id: :uuid, default: -> { "gen_random_uuid()" },
      comment: "Apple Wallet pass metadata (#35 B3)" do |t|
      t.uuid :order_id, null: false
      t.uuid :tenant_id, null: false
      t.uuid :customer_id
      t.string :serial_number, limit: 64, null: false
      t.string :authentication_token, limit: 64, null: false
      t.string :pass_type_identifier, limit: 128
      t.string :status_label, limit: 64, null: false, default: "accepted"
      t.integer :revision, null: false, default: 1
      t.timestamps
    end

    add_index :order_wallet_passes, :order_id, unique: true, name: "idx_order_wallet_passes_order"
    add_index :order_wallet_passes, :serial_number, unique: true, name: "idx_order_wallet_passes_serial"
    add_foreign_key :order_wallet_passes, :orders
    add_foreign_key :order_wallet_passes, :tenants
  end
end
