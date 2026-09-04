# frozen_string_literal: true

# #76: обобщённые точечные кампании (card_binding_promo и будущие типы).
class CreatePointCampaignSettings < ActiveRecord::Migration[8.0]
  def up
    create_table :point_campaign_settings, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :point_id, null: false
      t.string :campaign_type, null: false, limit: 64
      t.boolean :enabled, null: false, default: false
      t.integer :threshold, null: false, default: 100
      t.integer :counter, null: false, default: 0
      t.jsonb :config, null: false, default: {}
      t.timestamps null: false
    end

    add_index :point_campaign_settings, [ :point_id, :campaign_type ],
              unique: true, name: "idx_point_campaign_settings_point_type"
    add_foreign_key :point_campaign_settings, :tenants, column: :point_id

    execute "COMMENT ON TABLE point_campaign_settings IS '#76: point-level campaigns (card_binding_promo, …)'"

    execute "ALTER TABLE point_campaign_settings ENABLE ROW LEVEL SECURITY"

    execute <<-SQL
      CREATE POLICY rls_point_campaign_settings_isolation ON point_campaign_settings
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
    execute "DROP POLICY IF EXISTS rls_point_campaign_settings_isolation ON point_campaign_settings"
    drop_table :point_campaign_settings, if_exists: true
  end
end
