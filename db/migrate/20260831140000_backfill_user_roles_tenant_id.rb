# frozen_string_literal: true

# IB G-11: legacy user_roles без tenant_id давали point staff доступ в любом tenant
# через has_role_in_context? (nil tenant_id = global grant). Backfill из users.tenant_id.
class BackfillUserRolesTenantId < ActiveRecord::Migration[8.1]
  POINT_STAFF_ROLE_CODES = %w[
    barista shift_manager general_manager prep_kitchen_manager prep_kitchen_worker
  ].freeze

  def up
    codes_sql = POINT_STAFF_ROLE_CODES.map { |c| connection.quote(c) }.join(", ")

    execute <<~SQL.squish
      DELETE FROM user_roles ur_null
      USING roles r, users u
      WHERE ur_null.role_id = r.id
        AND ur_null.user_id = u.id
        AND ur_null.tenant_id IS NULL
        AND r.code IN (#{codes_sql})
        AND u.tenant_id IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM user_roles ur_scoped
          WHERE ur_scoped.user_id = ur_null.user_id
            AND ur_scoped.role_id = ur_null.role_id
            AND ur_scoped.tenant_id = u.tenant_id
        )
    SQL

    execute <<~SQL.squish
      UPDATE user_roles ur
      SET tenant_id = u.tenant_id
      FROM roles r, users u
      WHERE ur.user_id = u.id
        AND ur.role_id = r.id
        AND ur.tenant_id IS NULL
        AND r.code IN (#{codes_sql})
        AND u.tenant_id IS NOT NULL
    SQL

    execute <<~SQL.squish
      DELETE FROM user_roles ur
      USING roles r, users u
      WHERE ur.user_id = u.id
        AND ur.role_id = r.id
        AND ur.tenant_id IS NULL
        AND r.code IN (#{codes_sql})
        AND u.tenant_id IS NULL
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
