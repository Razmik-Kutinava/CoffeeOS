# frozen_string_literal: true

# Триггеры/часть RLS DDL не попадают в schema.rb — после db:schema:load восстанавливаем (R3-B).
module DatabaseTriggers
  module_function

  def ensure_all!
    ensure_order_number!
    ensure_auto_deduct!
    ensure_auto_stop_list!
  end

  def order_number_trigger_present?
    trigger_present?("trg_generate_order_number")
  end

  def trigger_present?(name)
    ActiveRecord::Base.connection.select_value(<<~SQL.squish).to_i.positive?
      SELECT COUNT(*) FROM pg_trigger WHERE tgname = #{ActiveRecord::Base.connection.quote(name)}
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

  def ensure_auto_deduct!
    # TASK_93-A: function is intentionally no-op (Ruby soft-fail deduction).
    # G only requires the trigger *to exist* after schema:load.
    conn = ActiveRecord::Base.connection
    conn.execute(<<~SQL)
      CREATE OR REPLACE FUNCTION auto_deduct_ingredients_on_order_accept()
      RETURNS TRIGGER AS $$
      BEGIN
        -- TASK_93-A: no-op. Deduction is Inventory::OrderRecipeDeduction (skip + audit on shortfall).
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    return if trigger_present?("trg_auto_deduct_ingredients")

    conn.execute("DROP TRIGGER IF EXISTS trg_auto_deduct_ingredients ON orders")
    conn.execute(<<~SQL)
      CREATE TRIGGER trg_auto_deduct_ingredients
      AFTER INSERT OR UPDATE ON orders
      FOR EACH ROW
      EXECUTE FUNCTION auto_deduct_ingredients_on_order_accept();
    SQL
  end

  def ensure_auto_stop_list!
    return if trigger_present?("trg_auto_stop_list")

    conn = ActiveRecord::Base.connection
    conn.execute(<<~SQL)
      CREATE OR REPLACE FUNCTION auto_stop_list_on_zero_stock()
      RETURNS TRIGGER AS $$
      DECLARE
        product_record RECORD;
      BEGIN
        IF NEW.qty <= 0 THEN
          FOR product_record IN
            SELECT DISTINCT pr.product_id
            FROM product_recipes pr
            WHERE pr.ingredient_id = NEW.ingredient_id
          LOOP
            UPDATE product_tenant_settings
            SET is_sold_out = TRUE, sold_out_reason = 'stock_empty', updated_at = NOW()
            WHERE product_id = product_record.product_id
              AND tenant_id = NEW.tenant_id
              AND is_sold_out = FALSE;
          END LOOP;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    conn.execute("DROP TRIGGER IF EXISTS trg_auto_stop_list ON ingredient_tenant_stocks")
    conn.execute(<<~SQL)
      CREATE TRIGGER trg_auto_stop_list
      AFTER UPDATE ON ingredient_tenant_stocks
      FOR EACH ROW
      WHEN (NEW.qty <= 0 AND (OLD.qty IS NULL OR OLD.qty > 0))
      EXECUTE FUNCTION auto_stop_list_on_zero_stock();
    SQL
  end
end
