# frozen_string_literal: true

# #78: guest PWA subscription plans / subscriptions / usage events (≠ platform billing_*).
class CreateGuestSubscriptionTables < ActiveRecord::Migration[8.0]
  def up
    create_table :subscription_plans, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :code, null: false, limit: 64
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :currency, null: false, default: "RUB", limit: 3
      t.integer :period_days, null: false
      t.integer :drink_limit, null: false
      t.decimal :discount_price_per_drink, precision: 10, scale: 2, null: false
      t.integer :over_limit_discount_percent, null: false
      t.datetime :launch_price_valid_until
      t.boolean :active, null: false, default: true
      t.timestamps null: false
    end
    add_index :subscription_plans, :code, unique: true, name: "idx_subscription_plans_code"
    add_index :subscription_plans, :active, name: "idx_subscription_plans_active"
    add_check_constraint :subscription_plans, "price >= 0", name: "chk_subscription_plans_price"
    add_check_constraint :subscription_plans, "period_days > 0", name: "chk_subscription_plans_period"
    add_check_constraint :subscription_plans, "drink_limit >= 0", name: "chk_subscription_plans_drink_limit"
    add_check_constraint :subscription_plans, "discount_price_per_drink >= 0", name: "chk_subscription_plans_discount_price"
    add_check_constraint :subscription_plans, "over_limit_discount_percent >= 0 AND over_limit_discount_percent <= 100",
                         name: "chk_subscription_plans_over_limit_pct"

    create_table :subscriptions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :customer_id, null: false
      t.uuid :plan_id, null: false
      t.uuid :purchase_point_id, null: false
      t.string :status, null: false, default: "pending", limit: 32
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.decimal :price_at_period_start, precision: 10, scale: 2
      t.integer :drink_limit_at_period_start
      t.integer :discount_percent_at_period_start
      t.integer :drinks_used_this_period, null: false, default: 0
      t.boolean :auto_renew, null: false, default: true
      t.uuid :payment_method_id
      t.uuid :payment_id
      t.timestamps null: false
    end
    add_index :subscriptions, :customer_id, name: "idx_subscriptions_customer"
    add_index :subscriptions, [ :customer_id, :status ], name: "idx_subscriptions_customer_status"
    add_index :subscriptions, :plan_id, name: "idx_subscriptions_plan"
    add_index :subscriptions, :current_period_end, name: "idx_subscriptions_period_end"
    add_foreign_key :subscriptions, :mobile_customers, column: :customer_id
    add_foreign_key :subscriptions, :subscription_plans, column: :plan_id
    add_foreign_key :subscriptions, :tenants, column: :purchase_point_id
    add_foreign_key :subscriptions, :mobile_payment_methods, column: :payment_method_id
    add_foreign_key :subscriptions, :payments, column: :payment_id
    add_check_constraint :subscriptions,
                         "status::text = ANY (ARRAY['pending'::text, 'active'::text, 'canceled'::text, 'past_due'::text])",
                         name: "chk_subscriptions_status"
    add_check_constraint :subscriptions, "drinks_used_this_period >= 0", name: "chk_subscriptions_drinks_used"

    create_table :subscription_usage_events, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :subscription_id, null: false
      t.uuid :order_id, null: false
      t.uuid :point_id, null: false
      t.decimal :applied_price, precision: 10, scale: 2, null: false
      t.decimal :savings_amount, precision: 10, scale: 2, null: false, default: "0.0"
      t.string :pricing_kind, null: false, limit: 32
      t.timestamps null: false
    end
    add_index :subscription_usage_events, :subscription_id, name: "idx_subscription_usage_events_sub"
    add_index :subscription_usage_events, :order_id, name: "idx_subscription_usage_events_order"
    add_foreign_key :subscription_usage_events, :subscriptions, column: :subscription_id
    add_foreign_key :subscription_usage_events, :orders, column: :order_id
    add_foreign_key :subscription_usage_events, :tenants, column: :point_id

    execute "COMMENT ON TABLE subscription_plans IS '#78: guest PWA subscription plans (not platform billing_plans)'"
    execute "COMMENT ON TABLE subscriptions IS '#78: guest PWA subscriptions (not billing_subscriptions)'"
    execute "COMMENT ON TABLE subscription_usage_events IS '#78: per-order subscription pricing usage'"
  end

  def down
    drop_table :subscription_usage_events, if_exists: true
    drop_table :subscriptions, if_exists: true
    drop_table :subscription_plans, if_exists: true
  end
end
