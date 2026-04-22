require "test_helper"

# Регрессионный тест на SQL-инъекцию через Current.tenant_id.
# Убеждаемся что conn.quote() корректно экранирует злой ввод.
class ApplicationRecordSqlTest < ActiveSupport::TestCase
  test "malicious tenant_id is escaped by conn.quote and cannot break out of string literal" do
    conn = ActiveRecord::Base.connection

    evil_input = "'; DROP TABLE tenants; --"
    quoted = conn.quote(evil_input)

    # quote оборачивает в одинарные кавычки и экранирует внутренние кавычки
    assert quoted.start_with?("'"), "quote must wrap in single quotes"
    assert quoted.end_with?("'"),   "quote must close with single quote"
    # Одинарная кавычка внутри должна быть экранирована как ''
    assert_includes quoted, "''"

    # Убеждаемся что строка может быть безопасно вставлена в SQL — таблица не упала
    conn.execute("SELECT 1 WHERE 'test' = #{quoted}")
    assert conn.table_exists?("tenants"), "tenants table must still exist after quoted evil input"
  end

  test "Current attributes reset between simulated requests" do
    Current.tenant_id = "tenant-a"
    Current.user_id   = 42

    # Simulating reset that CurrentAttributes does automatically per request
    Current.reset

    assert_nil Current.tenant_id
    assert_nil Current.user_id
  end
end
