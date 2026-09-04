# frozen_string_literal: true

# #77: point-scoped subscription offer CTA settings.
class CreateSubscriptionOfferSettings < ActiveRecord::Migration[8.0]
  def up
    create_table :subscription_offer_settings, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :point_id, null: false
      t.boolean :enabled, null: false, default: false
      t.string :second_cta_mode, null: false, default: "tips", limit: 32
      t.integer :min_completed_orders, null: false, default: 1
      t.integer :required_signals_count, null: false, default: 1
      t.timestamps null: false
    end

    add_index :subscription_offer_settings, :point_id, unique: true,
              name: "idx_subscription_offer_settings_point"
    add_foreign_key :subscription_offer_settings, :tenants, column: :point_id

    execute "COMMENT ON TABLE subscription_offer_settings IS '#77: point-scoped subscription offer CTA + eligibility thresholds'"

    execute "ALTER TABLE subscription_offer_settings ENABLE ROW LEVEL SECURITY"

    execute <<-SQL
      CREATE POLICY rls_subscription_offer_settings_isolation ON subscription_offer_settings
        FOR ALL
        USING (
          point_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code = 'ук_global_admin'
          )
        )
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS rls_subscription_offer_settings_isolation ON subscription_offer_settings"
    drop_table :subscription_offer_settings, if_exists: true
  end
end
