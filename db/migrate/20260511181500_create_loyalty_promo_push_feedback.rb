# frozen_string_literal: true

class CreateLoyaltyPromoPushFeedback < ActiveRecord::Migration[8.1]
  def up
    create_table :loyalty_accounts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :customer, type: :uuid, null: false, foreign_key: { to_table: :mobile_customers, on_delete: :cascade }, index: { unique: true }
      t.integer :balance, null: false, default: 0
      t.integer :lifetime_earned, null: false, default: 0
      t.integer :lifetime_spent, null: false, default: 0
      t.string :level, null: false, default: "bronze", limit: 50
      t.timestamps
    end

    add_check_constraint :loyalty_accounts, "balance >= 0", name: "chk_loyalty_balance"
    add_check_constraint :loyalty_accounts, "lifetime_earned >= 0", name: "chk_loyalty_lifetime_earned"
    add_check_constraint :loyalty_accounts, "lifetime_spent >= 0", name: "chk_loyalty_lifetime_spent"
    add_check_constraint :loyalty_accounts, "level IN ('bronze', 'silver', 'gold', 'platinum')", name: "chk_loyalty_level"
    add_index :loyalty_accounts, :level, if_not_exists: true

    create_table :loyalty_transactions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :customer, type: :uuid, null: false, foreign_key: { to_table: :mobile_customers, on_delete: :cascade }
      t.references :order, type: :uuid, null: true, foreign_key: { on_delete: :nullify }
      t.references :tenant, type: :uuid, null: true, foreign_key: { on_delete: :nullify }
      t.string :transaction_type, null: false, limit: 50
      t.integer :points, null: false
      t.integer :balance_after, null: false
      t.text :description
      t.references :created_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamp :created_at, null: false, default: -> { "NOW()" }
    end

    add_check_constraint :loyalty_transactions, "transaction_type IN ('earn', 'spend', 'expire', 'manual_add', 'manual_subtract')", name: "chk_loyalty_txn_type"
    add_check_constraint :loyalty_transactions, "points > 0", name: "chk_loyalty_txn_points"
    add_check_constraint :loyalty_transactions, "balance_after >= 0", name: "chk_loyalty_txn_balance_after"
    add_index :loyalty_transactions, [:customer_id, :created_at], order: { created_at: :desc }, if_not_exists: true, name: "idx_loyalty_tx_customer_created"
    add_index :loyalty_transactions, :order_id, if_not_exists: true
    add_index :loyalty_transactions, :tenant_id, if_not_exists: true
    add_index :loyalty_transactions, :transaction_type, if_not_exists: true, name: "idx_loyalty_tx_type"

    create_table :promo_code_usages, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :promo_code, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :customer, type: :uuid, null: true, foreign_key: { to_table: :mobile_customers, on_delete: :nullify }
      t.references :order, type: :uuid, null: true, foreign_key: { on_delete: :nullify }
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :discount_amount, precision: 10, scale: 2, null: false, default: 0
      t.timestamp :used_at, null: false, default: -> { "NOW()" }
      t.string :status, null: false, default: "applied", limit: 20
      t.timestamps
    end

    add_check_constraint :promo_code_usages, "discount_amount >= 0", name: "chk_promo_usage_discount"
    add_check_constraint :promo_code_usages, "status IN ('applied', 'reverted')", name: "chk_promo_usage_status"
    add_index :promo_code_usages, :promo_code_id, if_not_exists: true
    add_index :promo_code_usages, :customer_id, if_not_exists: true
    add_index :promo_code_usages, :order_id, if_not_exists: true
    add_index :promo_code_usages, [:tenant_id, :used_at], order: { used_at: :desc }, if_not_exists: true, name: "idx_promo_usage_tenant_used"

    create_table :push_notifications, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :customer, type: :uuid, null: false, foreign_key: { to_table: :mobile_customers, on_delete: :cascade }
      t.references :tenant, type: :uuid, null: true, foreign_key: { on_delete: :nullify }
      t.string :notification_type, null: false, limit: 50
      t.string :title, null: false, limit: 255
      t.text :body, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :status, null: false, default: "pending", limit: 50
      t.timestamp :scheduled_at
      t.timestamp :sent_at
      t.timestamp :read_at
      t.text :error_message
      t.timestamps
    end

    add_check_constraint :push_notifications, "status IN ('pending', 'sent', 'failed', 'read')", name: "chk_push_status"
    add_index :push_notifications, [:customer_id, :created_at], order: { created_at: :desc }, if_not_exists: true, name: "idx_push_customer_created"
    add_index :push_notifications, [:tenant_id, :notification_type], if_not_exists: true, name: "idx_push_tenant_type"
    add_index :push_notifications, :status, if_not_exists: true
    add_index :push_notifications, :scheduled_at, if_not_exists: true

    create_table :order_feedback, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :order, type: :uuid, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.references :customer, type: :uuid, null: false, foreign_key: { to_table: :mobile_customers, on_delete: :cascade }
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.integer :rating, null: false
      t.text :comment
      t.string :sentiment, limit: 20
      t.string :positive_tags, array: true, default: []
      t.string :negative_tags, array: true, default: []
      t.boolean :resolved, null: false, default: false
      t.references :resolved_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamp :resolved_at
      t.timestamps
    end

    add_check_constraint :order_feedback, "rating BETWEEN 1 AND 5", name: "chk_feedback_rating"
    add_check_constraint :order_feedback, "sentiment IS NULL OR sentiment IN ('positive', 'neutral', 'negative')", name: "chk_feedback_sentiment"
    add_index :order_feedback, [:tenant_id, :created_at], order: { created_at: :desc }, if_not_exists: true, name: "idx_feedback_tenant_created"
    add_index :order_feedback, :rating, if_not_exists: true
    add_index :order_feedback, :resolved, if_not_exists: true
    add_index :order_feedback, :positive_tags, using: :gin, if_not_exists: true
    add_index :order_feedback, :negative_tags, using: :gin, if_not_exists: true
  end

  def down
    drop_table :order_feedback, if_exists: true
    drop_table :push_notifications, if_exists: true
    drop_table :promo_code_usages, if_exists: true
    drop_table :loyalty_transactions, if_exists: true
    drop_table :loyalty_accounts, if_exists: true
  end
end
