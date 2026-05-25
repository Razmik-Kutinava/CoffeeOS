# frozen_string_literal: true

# schema.rb не содержит триггеры — после db:schema:load номера заказов не генерируются.
class EnsureOrderNumberTrigger < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
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

    execute "DROP TRIGGER IF EXISTS trg_generate_order_number ON orders"

    execute <<-SQL
      CREATE TRIGGER trg_generate_order_number
      BEFORE INSERT ON orders
      FOR EACH ROW
      WHEN (NEW.order_number IS NULL OR NEW.order_number = '')
      EXECUTE FUNCTION generate_order_number();
    SQL

    backfill_empty_order_numbers!
  end

  def down
    execute "DROP TRIGGER IF EXISTS trg_generate_order_number ON orders"
    execute "DROP FUNCTION IF EXISTS generate_order_number()"
  end

  private

  def backfill_empty_order_numbers!
    execute <<-SQL
      WITH numbered AS (
        SELECT
          id,
          ROW_NUMBER() OVER (
            PARTITION BY tenant_id, DATE_TRUNC('month', created_at)
            ORDER BY created_at, id
          ) AS seq,
          tenant_id,
          created_at
        FROM orders
        WHERE order_number IS NULL OR order_number = ''
      )
      UPDATE orders AS o
      SET
        order_number = '#' || TO_CHAR(n.created_at, 'YYYYMM') || '-' || LPAD(n.seq::TEXT, 4, '0'),
        order_sequence = n.seq
      FROM numbered AS n
      WHERE o.id = n.id;
    SQL
  end
end
