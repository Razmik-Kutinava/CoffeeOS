# frozen_string_literal: true

# TASK_93-A: единственный канон списания — Inventory::OrderRecipeDeduction (soft-fail).
# Старый trg_auto_deduct hard-subtract давал negative stock и double-deduct с Ruby на UPDATE→accepted.
class Task93aDisableHardAutoDeductTrigger < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION auto_deduct_ingredients_on_order_accept()
      RETURNS TRIGGER AS $$
      BEGIN
        -- TASK_93-A: no-op. Deduction is Inventory::OrderRecipeDeduction (skip + audit on shortfall).
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL
      COMMENT ON FUNCTION auto_deduct_ingredients_on_order_accept() IS
        'TASK_93-A no-op: stock deduct via Inventory::OrderRecipeDeduction soft-fail only';
    SQL
  end

  def down
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

    execute <<~SQL
      COMMENT ON FUNCTION auto_deduct_ingredients_on_order_accept() IS
        'Block F: списание по product_recipes при accepted (INSERT или UPDATE); отрицательный остаток допустим';
    SQL
  end
end
