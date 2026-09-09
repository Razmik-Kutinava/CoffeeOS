# frozen_string_literal: true

# V3-SEC-SHOP-API-KEYS: per-tenant shop API keys (digest only).
# Lookup до tenant GUC: Rls::GucContext.with_shop_api_key_lookup (без row_security off).
class CreateShopApiKeys < ActiveRecord::Migration[8.1]
  def up
    create_table :shop_api_keys, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :tenant_id
      t.string :name, null: false
      t.string :token_digest, null: false
      t.string :token_prefix
      t.boolean :active, null: false, default: true
      t.boolean :global_ops, null: false, default: false
      t.datetime :expires_at
      t.datetime :revoked_at
      t.datetime :last_used_at
      t.timestamps
    end

    add_index :shop_api_keys, :token_digest, unique: true, name: "index_shop_api_keys_on_token_digest"
    add_index :shop_api_keys, :tenant_id, name: "index_shop_api_keys_on_tenant_id"
    add_foreign_key :shop_api_keys, :tenants, column: :tenant_id, on_delete: :cascade

    execute "ALTER TABLE shop_api_keys ENABLE ROW LEVEL SECURITY"

    execute <<-SQL.squish
      CREATE POLICY rls_shop_api_keys_isolation ON shop_api_keys
        FOR ALL
        USING (
          tenant_id IS NOT NULL
          AND tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
        WITH CHECK (
          tenant_id IS NOT NULL
          AND tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL

    execute <<-SQL.squish
      CREATE POLICY rls_shop_api_keys_lookup ON shop_api_keys
        FOR ALL
        USING (NULLIF(current_setting('app.shop_api_key_lookup', true), '') = 'on')
        WITH CHECK (NULLIF(current_setting('app.shop_api_key_lookup', true), '') = 'on')
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS rls_shop_api_keys_lookup ON shop_api_keys"
    execute "DROP POLICY IF EXISTS rls_shop_api_keys_isolation ON shop_api_keys"
    drop_table :shop_api_keys
  end
end
