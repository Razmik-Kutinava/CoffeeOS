class EnablePgStatStatements < ActiveRecord::Migration[8.1]
  def up
    # Требует superuser в PostgreSQL.
    # В Docker: добавить shared_preload_libraries = 'pg_stat_statements' в postgresql.conf
    execute "CREATE EXTENSION IF NOT EXISTS pg_stat_statements"
  rescue ActiveRecord::StatementInvalid => e
    warn "pg_stat_statements: #{e.message} — пропускаем (нет прав superuser)"
  end

  def down
    execute "DROP EXTENSION IF EXISTS pg_stat_statements"
  rescue ActiveRecord::StatementInvalid
    # ignore
  end
end
