# frozen_string_literal: true

class AddRlsTenantsShopCityLookupPolicy < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      ALTER TABLE tenants ENABLE ROW LEVEL SECURITY
    SQL

    # Owner/bypass still sees all rows unless FORCE — do not FORCE (platform/onboarding).
    execute <<~SQL.squish
      DROP POLICY IF EXISTS rls_tenants_shop_city_lookup ON tenants;
      CREATE POLICY rls_tenants_shop_city_lookup ON tenants
        FOR SELECT
        USING (
          NULLIF(current_setting('app.shop_city_lookup', true), '') = 'on'
          AND status = 'active'
          AND type = 'sales_point'
        )
    SQL

    execute <<~SQL.squish
      DROP POLICY IF EXISTS rls_orders_shop_city_lookup ON orders;
      CREATE POLICY rls_orders_shop_city_lookup ON orders
        FOR SELECT
        USING (NULLIF(current_setting('app.shop_city_lookup', true), '') = 'on')
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS rls_orders_shop_city_lookup ON orders"
    execute "DROP POLICY IF EXISTS rls_tenants_shop_city_lookup ON tenants"
    execute "ALTER TABLE tenants DISABLE ROW LEVEL SECURITY"
  end
end
