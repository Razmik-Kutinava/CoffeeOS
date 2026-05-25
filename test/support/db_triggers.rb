# frozen_string_literal: true

# Обеспечивает наличие триггеров auto_deduct и auto_stop_list в тестовой БД.
# schema.rb не содержит триггеры, поэтому при db:schema:load они не создаются.
module TestDbTriggers
  class << self
    def ensure!
      conn = ActiveRecord::Base.connection

      conn.execute(<<~SQL)
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
          IF NEW.status = 'accepted'
            AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM 'accepted')
          THEN
            FOR item IN SELECT * FROM order_items WHERE order_id = NEW.id LOOP
              FOR recipe IN SELECT * FROM product_recipes WHERE product_id = item.product_id LOOP
                qty_needed := recipe.qty_per_serving * item.quantity;

                IF item.modifier_options IS NOT NULL
                  AND item.modifier_options ? 'selected_modifiers'
                  AND jsonb_typeof(item.modifier_options->'selected_modifiers') = 'array'
                THEN
                  FOR mod_element IN
                    SELECT jsonb_array_elements(item.modifier_options->'selected_modifiers')
                  LOOP
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

      conn.execute("DROP TRIGGER IF EXISTS trg_auto_deduct_ingredients ON orders")
      conn.execute(<<~SQL)
        CREATE TRIGGER trg_auto_deduct_ingredients
        AFTER INSERT OR UPDATE ON orders
        FOR EACH ROW
        EXECUTE FUNCTION auto_deduct_ingredients_on_order_accept();
      SQL

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
end
