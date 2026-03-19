# frozen_string_literal: true

# Обеспечивает наличие триггеров auto_deduct и auto_stop_list в тестовой БД.
# schema.rb не содержит триггеры, поэтому при db:schema:load они не создаются.
# Этот модуль создаёт их при первом запуске тестов DbTriggersTest.
module TestDbTriggers
  class << self
    def ensure!
      # Не кешируем: каждый тест в своей транзакции, при rollback триггеры исчезают.
      conn = ActiveRecord::Base.connection

      # auto_deduct
      conn.execute(<<~SQL)
        CREATE OR REPLACE FUNCTION auto_deduct_ingredients_on_order_accept()
        RETURNS TRIGGER AS $$
        DECLARE
          item RECORD;
          recipe RECORD;
          modifier_recipe RECORD;
          qty_needed DECIMAL;
          current_stock RECORD;
        BEGIN
          IF NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status::text != 'accepted') THEN
            FOR item IN SELECT * FROM order_items WHERE order_id = NEW.id LOOP
              FOR recipe IN SELECT * FROM product_recipes WHERE product_id = item.product_id LOOP
                qty_needed := recipe.qty_per_serving * item.quantity;
                IF item.modifier_options IS NOT NULL AND jsonb_typeof(item.modifier_options) = 'object' THEN
                  FOR modifier_recipe IN
                    SELECT mor.* FROM modifier_option_recipes mor
                    WHERE mor.option_id IN (
                      SELECT value::uuid FROM jsonb_each_text(item.modifier_options)
                    )
                    AND mor.ingredient_id = recipe.ingredient_id
                  LOOP
                    qty_needed := qty_needed + (modifier_recipe.qty_change * item.quantity);
                  END LOOP;
                END IF;
                SELECT * INTO current_stock
                FROM ingredient_tenant_stocks
                WHERE tenant_id = NEW.tenant_id AND ingredient_id = recipe.ingredient_id;
                IF current_stock IS NULL THEN
                  INSERT INTO ingredient_tenant_stocks (tenant_id, ingredient_id, qty, created_at, updated_at)
                  VALUES (NEW.tenant_id, recipe.ingredient_id, 0, NOW(), NOW());
                END IF;
                UPDATE ingredient_tenant_stocks
                SET qty = qty - qty_needed, last_updated_at = NOW(), updated_at = NOW()
                WHERE tenant_id = NEW.tenant_id AND ingredient_id = recipe.ingredient_id;
              END LOOP;
            END LOOP;
          END IF;
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      SQL

      conn.execute("DROP TRIGGER IF EXISTS trg_auto_deduct_ingredients ON orders")
      conn.execute(<<~SQL)
        CREATE TRIGGER trg_auto_deduct_ingredients
        AFTER UPDATE ON orders
        FOR EACH ROW
        WHEN (NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status::text != 'accepted'))
        EXECUTE FUNCTION auto_deduct_ingredients_on_order_accept();
      SQL

      # auto_stop_list
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

      @ensured = true
    end
  end
end
