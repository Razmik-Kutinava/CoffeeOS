# frozen_string_literal: true

# G-12: один production_kitchen обслуживает несколько точек продаж.
class CreatePrepKitchenSalesPointLinks < ActiveRecord::Migration[8.1]
  def up
    create_table :prep_kitchen_sales_point_links, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :prep_kitchen_tenant, type: :uuid, null: false, foreign_key: { to_table: :tenants, on_delete: :cascade }
      t.references :sales_point_tenant, type: :uuid, null: false, foreign_key: { to_table: :tenants, on_delete: :cascade }
      t.timestamps
    end

    add_index :prep_kitchen_sales_point_links,
              :sales_point_tenant_id,
              unique: true,
              name: "idx_prep_kitchen_links_sales_point_unique"
    add_index :prep_kitchen_sales_point_links,
              :prep_kitchen_tenant_id,
              name: "idx_prep_kitchen_links_kitchen"

    execute "ALTER TABLE prep_kitchen_sales_point_links ENABLE ROW LEVEL SECURITY"
    execute <<-SQL.squish
      CREATE POLICY rls_prep_kitchen_sales_point_links ON prep_kitchen_sales_point_links
        FOR ALL
        USING (
          prep_kitchen_tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR sales_point_tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
        WITH CHECK (
          prep_kitchen_tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR sales_point_tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS rls_prep_kitchen_sales_point_links ON prep_kitchen_sales_point_links"
    drop_table :prep_kitchen_sales_point_links
  end
end
