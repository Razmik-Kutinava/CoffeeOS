# frozen_string_literal: true

# Block F: списание при INSERT accepted + допуск отрицательного остатка (QA 4.2).
class BlockFStockDeduction < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :ingredient_tenant_stocks, name: "chk_stock_qty", if_exists: true

    execute <<~SQL
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

    execute "DROP TRIGGER IF EXISTS trg_auto_deduct_ingredients ON orders"
    execute <<~SQL
      CREATE TRIGGER trg_auto_deduct_ingredients
      AFTER INSERT OR UPDATE ON orders
      FOR EACH ROW
      EXECUTE FUNCTION auto_deduct_ingredients_on_order_accept();
    SQL

    execute <<~SQL
      COMMENT ON FUNCTION auto_deduct_ingredients_on_order_accept() IS
        'Block F: списание по product_recipes при accepted (INSERT или UPDATE); отрицательный остаток допустим';
    SQL
  end

  def down
    add_check_constraint :ingredient_tenant_stocks, "qty >= 0::numeric", name: "chk_stock_qty"

    execute "DROP TRIGGER IF EXISTS trg_auto_deduct_ingredients ON orders"
    execute <<~SQL
      CREATE TRIGGER trg_auto_deduct_ingredients
      AFTER UPDATE ON orders
      FOR EACH ROW
      WHEN (NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status::text != 'accepted'))
      EXECUTE FUNCTION auto_deduct_ingredients_on_order_accept();
    SQL
  end
end
