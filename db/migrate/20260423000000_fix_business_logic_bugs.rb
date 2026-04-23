class FixBusinessLogicBugs < ActiveRecord::Migration[8.1]
  def up
    # ===========================================================================
    # BUG-018 FIX: Уникальный индекс — не более одного успешного платежа на заказ.
    # Предотвращает двойное списание при дублирующихся callbacks от провайдера.
    # ===========================================================================
    execute <<-SQL
      CREATE UNIQUE INDEX IF NOT EXISTS idx_one_succeeded_payment_per_order
      ON payments(order_id)
      WHERE status = 'succeeded';
    SQL

    execute "COMMENT ON INDEX idx_one_succeeded_payment_per_order IS 'BUG-018: Один успешный платёж на заказ'"

    # ===========================================================================
    # BUG-001 FIX: Генерация order_number с блокировкой (SELECT FOR UPDATE).
    # Исходная функция использует MAX() без блокировки — возможен race condition
    # при одновременном создании заказов в одном тенанте.
    # ===========================================================================
    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_order_number()
      RETURNS TRIGGER AS $$
      DECLARE
        new_sequence BIGINT;
        year_month TEXT;
        lock_key BIGINT;
      BEGIN
        -- BUG-001 FIX: Используем advisory lock на tenant_id чтобы исключить race condition.
        -- Ключ = hash от tenant_id UUID для предсказуемости.
        lock_key := abs(hashtext(NEW.tenant_id::text));
        PERFORM pg_advisory_xact_lock(lock_key);

        SELECT COALESCE(MAX(order_sequence), 0) + 1 INTO new_sequence
        FROM orders
        WHERE tenant_id = NEW.tenant_id
          AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', NOW());

        year_month := TO_CHAR(NOW(), 'YYYYMM');
        NEW.order_number := '#' || year_month || '-' || LPAD(new_sequence::TEXT, 4, '0');
        NEW.order_sequence := new_sequence;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute "COMMENT ON FUNCTION generate_order_number() IS 'BUG-001 FIX: Генерация order_number с advisory lock против race condition'"

    # ===========================================================================
    # BUG-011 FIX: Автостоп теперь фильтрует по tenant_id.
    # Раньше обнуление склада в одной точке останавливало товары ВО ВСЕХ точках сети.
    # ===========================================================================
    execute <<-SQL
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
            -- BUG-011 FIX: Фильтруем по NEW.tenant_id — стоп только для этой точки.
            UPDATE product_tenant_settings
            SET is_sold_out = TRUE,
                sold_out_reason = 'stock_empty',
                updated_at = NOW()
            WHERE product_id = product_record.product_id
              AND tenant_id = NEW.tenant_id
              AND is_sold_out = FALSE;
          END LOOP;
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute "COMMENT ON FUNCTION auto_stop_list_on_zero_stock() IS 'BUG-011 FIX: Автостоп только для конкретного тенанта, не всей сети'"

    # ===========================================================================
    # BUG-012 FIX: Корректное чтение модификаторов из JSONB при списании склада.
    # Раньше использовался jsonb_each_text() на {"selected_modifiers":[...]},
    # что давало одну строку с ключом "selected_modifiers" вместо ID модификаторов.
    # ===========================================================================
    execute <<-SQL
      CREATE OR REPLACE FUNCTION auto_deduct_ingredients_on_order_accept()
      RETURNS TRIGGER AS $$
      DECLARE
        item RECORD;
        recipe RECORD;
        modifier_recipe RECORD;
        qty_needed DECIMAL;
        mod_id UUID;
        mod_element JSONB;
      BEGIN
        IF NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status != 'accepted') THEN

          FOR item IN SELECT * FROM order_items WHERE order_id = NEW.id LOOP

            FOR recipe IN SELECT * FROM product_recipes WHERE product_id = item.product_id LOOP

              qty_needed := recipe.qty_per_serving * item.quantity;

              -- BUG-012 FIX: Правильно читаем selected_modifiers из JSONB.
              -- Структура: {"selected_modifiers": [{"id": "uuid", "name": "...", "price": 0}, ...]}
              IF item.modifier_options IS NOT NULL
                AND item.modifier_options ? 'selected_modifiers'
                AND jsonb_typeof(item.modifier_options->'selected_modifiers') = 'array'
              THEN
                FOR mod_element IN
                  SELECT jsonb_array_elements(item.modifier_options->'selected_modifiers')
                LOOP
                  -- Пропускаем элементы без валидного id
                  CONTINUE WHEN mod_element->>'id' IS NULL OR mod_element->>'id' = '';

                  BEGIN
                    mod_id := (mod_element->>'id')::UUID;
                  EXCEPTION WHEN invalid_text_representation THEN
                    CONTINUE;
                  END;

                  FOR modifier_recipe IN
                    SELECT mor.*
                    FROM modifier_option_recipes mor
                    WHERE mor.option_id = mod_id
                      AND mor.ingredient_id = recipe.ingredient_id
                  LOOP
                    qty_needed := qty_needed + (modifier_recipe.qty_change * item.quantity);
                  END LOOP;
                END LOOP;
              END IF;

              -- Списываем ингредиент (допускаем отрицательный остаток — CHECK constraint в БД)
              INSERT INTO ingredient_tenant_stocks (tenant_id, ingredient_id, qty, created_at, updated_at)
              VALUES (NEW.tenant_id, recipe.ingredient_id, -qty_needed, NOW(), NOW())
              ON CONFLICT (tenant_id, ingredient_id)
              DO UPDATE SET
                qty = ingredient_tenant_stocks.qty - qty_needed,
                last_updated_at = NOW(),
                updated_at = NOW();

            END LOOP;
          END LOOP;
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute "COMMENT ON FUNCTION auto_deduct_ingredients_on_order_accept() IS 'BUG-012 FIX: Корректное чтение selected_modifiers из JSONB при списании склада'"
  end

  def down
    execute "DROP INDEX IF EXISTS idx_one_succeeded_payment_per_order"

    # Восстанавливаем исходные версии функций (без фиксов)
    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_order_number()
      RETURNS TRIGGER AS $$
      DECLARE
        new_sequence BIGINT;
        year_month TEXT;
      BEGIN
        SELECT COALESCE(MAX(order_sequence), 0) + 1 INTO new_sequence
        FROM orders
        WHERE tenant_id = NEW.tenant_id
          AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', NOW());

        year_month := TO_CHAR(NOW(), 'YYYYMM');
        NEW.order_number := '#' || year_month || '-' || LPAD(new_sequence::TEXT, 4, '0');
        NEW.order_sequence := new_sequence;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute <<-SQL
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
            SET is_sold_out = TRUE,
                sold_out_reason = 'stock_empty',
                updated_at = NOW()
            WHERE product_id = product_record.product_id
              AND is_sold_out = FALSE;
          END LOOP;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end
end
