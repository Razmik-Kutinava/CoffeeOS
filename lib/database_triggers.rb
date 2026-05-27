# frozen_string_literal: true

# Триггеры PostgreSQL не попадают в schema.rb — после db:schema:load их нужно восстановить.
module DatabaseTriggers
  module_function

  def order_number_trigger_present?
    ActiveRecord::Base.connection.select_value(<<~SQL.squish).to_i.positive?
      SELECT COUNT(*) FROM pg_trigger WHERE tgname = 'trg_generate_order_number'
    SQL
  end

  def ensure_order_number!
    return if order_number_trigger_present?

    conn = ActiveRecord::Base.connection
    conn.execute(<<~SQL)
      CREATE OR REPLACE FUNCTION generate_order_number()
      RETURNS TRIGGER AS $$
      DECLARE
        new_sequence BIGINT;
        year_month TEXT;
        lock_key BIGINT;
      BEGIN
        IF NEW.order_number IS NOT NULL AND NEW.order_number <> '' THEN
          RETURN NEW;
        END IF;

        lock_key := abs(hashtext(NEW.tenant_id::text));
        PERFORM pg_advisory_xact_lock(lock_key);

        SELECT COALESCE(MAX(order_sequence), 0) + 1 INTO new_sequence
        FROM orders
        WHERE tenant_id = NEW.tenant_id
          AND DATE_TRUNC('month', created_at) =
              DATE_TRUNC('month', COALESCE(NEW.created_at, NOW()));

        year_month := TO_CHAR(COALESCE(NEW.created_at, NOW()), 'YYYYMM');
        NEW.order_number := '#' || year_month || '-' || LPAD(new_sequence::TEXT, 4, '0');
        NEW.order_sequence := new_sequence;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    conn.execute("DROP TRIGGER IF EXISTS trg_generate_order_number ON orders")
    conn.execute(<<~SQL)
      CREATE TRIGGER trg_generate_order_number
      BEFORE INSERT ON orders
      FOR EACH ROW
      WHEN (NEW.order_number IS NULL OR NEW.order_number = '')
      EXECUTE FUNCTION generate_order_number();
    SQL
  end
end
