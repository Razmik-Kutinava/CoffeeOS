# frozen_string_literal: true

# G-06: избранное гостя в БД (per customer + tenant), не только session.
class CreateShopCustomerFavorites < ActiveRecord::Migration[8.1]
  def up
    create_table :shop_customer_favorites, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :customer, type: :uuid, null: false, foreign_key: { to_table: :mobile_customers, on_delete: :cascade }
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :product, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end

    add_index :shop_customer_favorites,
              %i[customer_id tenant_id product_id],
              unique: true,
              name: "idx_shop_customer_favorites_unique"

    execute "ALTER TABLE shop_customer_favorites ENABLE ROW LEVEL SECURITY"
    execute <<-SQL.squish
      CREATE POLICY rls_shop_customer_favorites_isolation ON shop_customer_favorites
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
        WITH CHECK (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS rls_shop_customer_favorites_isolation ON shop_customer_favorites"
    drop_table :shop_customer_favorites
  end
end
