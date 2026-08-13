# frozen_string_literal: true

# B1.11: режим работы точки — расписание по дням недели (УК → витрина → табло)
class CreateTenantWeekdaySchedules < ActiveRecord::Migration[8.1]
  def up
    create_table :tenant_weekday_schedules, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :tenant_id, null: false
      t.integer :weekday, null: false, comment: "0=monday … 6=sunday"
      t.boolean :enabled, null: false, default: false
      t.time :opens_at
      t.time :closes_at
      t.timestamps
    end

    add_index :tenant_weekday_schedules, [ :tenant_id, :weekday ], unique: true, if_not_exists: true
    add_foreign_key :tenant_weekday_schedules, :tenants, column: :tenant_id, if_not_exists: true

    execute "COMMENT ON TABLE tenant_weekday_schedules IS 'B1.11: часы работы точки по дням недели'"

    execute "ALTER TABLE tenant_weekday_schedules ENABLE ROW LEVEL SECURITY"

    execute <<-SQL
      CREATE POLICY rls_tenant_weekday_schedules_isolation ON tenant_weekday_schedules
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
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
    execute "DROP POLICY IF EXISTS rls_tenant_weekday_schedules_isolation ON tenant_weekday_schedules"
    drop_table :tenant_weekday_schedules, if_exists: true
  end
end
