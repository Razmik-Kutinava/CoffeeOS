# frozen_string_literal: true

class CreateBillingAndTenantInvitations < ActiveRecord::Migration[8.1]
  def up
    create_table :billing_plans, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :code, null: false, limit: 50
      t.string :name, null: false, limit: 100
      t.text :description
      t.decimal :price_monthly, precision: 10, scale: 2, null: false, default: 0
      t.decimal :price_yearly, precision: 10, scale: 2
      t.integer :max_devices
      t.integer :max_products
      t.integer :max_staff
      t.jsonb :features, null: false, default: {}
      t.boolean :is_active, null: false, default: true
      t.integer :sort_order, null: false, default: 0
      t.timestamps
    end

    add_index :billing_plans, :code, unique: true, if_not_exists: true
    add_index :billing_plans, [ :is_active, :sort_order ], if_not_exists: true
    add_check_constraint :billing_plans, "price_monthly >= 0", name: "chk_billing_price"

    add_column :tenants, :plan_id, :uuid unless column_exists?(:tenants, :plan_id)
    add_foreign_key :tenants, :billing_plans, column: :plan_id, on_delete: :nullify unless foreign_key_exists?(:tenants, :billing_plans, column: :plan_id)
    add_index :tenants, :plan_id, if_not_exists: true

    create_table :billing_subscriptions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :plan, type: :uuid, null: false, foreign_key: { to_table: :billing_plans, on_delete: :restrict }
      t.string :billing_period, null: false, default: "monthly", limit: 20
      t.string :status, null: false, default: "active", limit: 50
      t.timestamp :started_at, null: false, default: -> { "NOW()" }
      t.timestamp :expires_at
      t.timestamp :cancelled_at
      t.decimal :amount_paid, precision: 10, scale: 2, default: 0
      t.string :payment_reference, limit: 255
      t.references :created_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end

    add_check_constraint :billing_subscriptions, "billing_period IN ('monthly', 'yearly', 'trial', 'free')", name: "chk_billing_period"
    add_check_constraint :billing_subscriptions, "status IN ('active', 'cancelled', 'expired', 'past_due')", name: "chk_subscription_status"
    add_check_constraint :billing_subscriptions, "amount_paid >= 0", name: "chk_amount_paid"
    add_index :billing_subscriptions, [ :tenant_id, :status ], if_not_exists: true, name: "idx_billing_subscriptions_tenant_status"
    add_index :billing_subscriptions, :plan_id, if_not_exists: true, name: "idx_billing_subscriptions_plan"
    add_index :billing_subscriptions, :expires_at, if_not_exists: true, where: "status = 'active'", name: "idx_billing_subscriptions_expires"

    create_table :tenant_invitations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :email, null: false, limit: 255
      t.references :role, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.uuid :token, null: false, default: -> { "gen_random_uuid()" }
      t.references :invited_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :status, null: false, default: "pending", limit: 50
      t.timestamp :expires_at, null: false, default: -> { "NOW() + INTERVAL '7 days'" }
      t.timestamp :accepted_at
      t.references :accepted_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamp :created_at, null: false, default: -> { "NOW()" }
    end

    add_index :tenant_invitations, :token, unique: true, if_not_exists: true, name: "idx_tenant_invitations_token"
    add_index :tenant_invitations, [ :tenant_id, :status ], if_not_exists: true, name: "idx_tenant_invitations_tenant_status"
    add_index :tenant_invitations, [ :email, :status ], if_not_exists: true, name: "idx_tenant_invitations_email_status"
    add_check_constraint :tenant_invitations, "status IN ('pending', 'accepted', 'expired', 'cancelled')", name: "chk_invitation_status"
  end

  def down
    remove_check_constraint :tenant_invitations, name: "chk_invitation_status" if check_constraint_exists?(:tenant_invitations, name: "chk_invitation_status")
    drop_table :tenant_invitations, if_exists: true

    remove_check_constraint :billing_subscriptions, name: "chk_amount_paid" if check_constraint_exists?(:billing_subscriptions, name: "chk_amount_paid")
    remove_check_constraint :billing_subscriptions, name: "chk_subscription_status" if check_constraint_exists?(:billing_subscriptions, name: "chk_subscription_status")
    remove_check_constraint :billing_subscriptions, name: "chk_billing_period" if check_constraint_exists?(:billing_subscriptions, name: "chk_billing_period")
    drop_table :billing_subscriptions, if_exists: true

    remove_foreign_key :tenants, column: :plan_id if foreign_key_exists?(:tenants, column: :plan_id)
    remove_index :tenants, :plan_id if index_exists?(:tenants, :plan_id)
    remove_column :tenants, :plan_id if column_exists?(:tenants, :plan_id)

    remove_check_constraint :billing_plans, name: "chk_billing_price" if check_constraint_exists?(:billing_plans, name: "chk_billing_price")
    drop_table :billing_plans, if_exists: true
  end
end
