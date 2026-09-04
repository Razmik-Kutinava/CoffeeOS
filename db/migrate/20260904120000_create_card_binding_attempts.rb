# frozen_string_literal: true

class CreateCardBindingAttempts < ActiveRecord::Migration[8.0]
  def change
    create_table :card_binding_attempts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :method_type, limit: 20, null: false
      t.string :method_hash, limit: 64
      t.string :phone, limit: 20
      t.uuid :account_id
      t.string :device_fingerprint, limit: 128
      t.string :ip, limit: 64
      t.string :bin, limit: 8
      t.uuid :point_id
      t.string :result, limit: 64, null: false, default: "ok"
      t.string :reason, limit: 128
      t.boolean :verification_charge_required, null: false, default: false
      t.boolean :is_growth_event, null: false, default: false
      t.timestamps null: false
    end

    add_index :card_binding_attempts, :method_hash, name: "idx_card_binding_attempts_method_hash"
    add_index :card_binding_attempts, :phone, name: "idx_card_binding_attempts_phone"
    add_index :card_binding_attempts, [:is_growth_event, :phone], name: "idx_card_binding_attempts_growth_phone"
    add_index :card_binding_attempts, [:is_growth_event, :method_hash], name: "idx_card_binding_attempts_growth_hash"
  end
end
