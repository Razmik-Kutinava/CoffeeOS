# frozen_string_literal: true

# TASK_95: персональное состояние оффера подписки на гостя (customer-scoped, как subscriptions — без RLS).
class CreateSubscriptionOfferStates < ActiveRecord::Migration[8.0]
  def up
    create_table :subscription_offer_states, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :customer_id, null: false
      t.string :status, null: false, default: "not_shown", limit: 32
      t.datetime :first_shown_at
      t.datetime :last_dismissed_at
      t.integer :completed_orders_count_at_dismissal
      t.datetime :unread_since
      t.timestamps null: false
    end
    add_index :subscription_offer_states, :customer_id, unique: true, name: "idx_subscription_offer_states_customer"
    add_foreign_key :subscription_offer_states, :mobile_customers, column: :customer_id
    add_check_constraint :subscription_offer_states,
                         "status::text = ANY (ARRAY['not_shown'::text, 'shown'::text, 'dismissed'::text, " \
                         "'viewed_in_lk'::text, 'purchased'::text])",
                         name: "chk_subscription_offer_states_status"

    execute "COMMENT ON TABLE subscription_offer_states IS 'TASK_95: guest subscription offer presentation state'"
  end

  def down
    drop_table :subscription_offer_states, if_exists: true
  end
end
