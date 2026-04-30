class FixAutostopTriggerRestore < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION auto_stop_list_on_zero_stock()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NEW.qty <= 0 THEN
          UPDATE product_tenant_settings pts
          SET    is_sold_out      = TRUE,
                 sold_out_reason  = 'stock_empty',
                 updated_at       = NOW()
          FROM   product_recipes pr
          WHERE  pr.ingredient_id = NEW.ingredient_id
            AND  pts.product_id   = pr.product_id
            AND  pts.tenant_id    = NEW.tenant_id
            AND  pts.is_sold_out  = FALSE;

        ELSIF NEW.qty > 0 AND OLD.qty <= 0 THEN
          UPDATE product_tenant_settings pts
          SET    is_sold_out      = FALSE,
                 sold_out_reason  = NULL,
                 updated_at       = NOW()
          FROM   product_recipes pr
          WHERE  pr.ingredient_id = NEW.ingredient_id
            AND  pts.product_id   = pr.product_id
            AND  pts.tenant_id    = NEW.tenant_id
            AND  pts.sold_out_reason = 'stock_empty';
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end

  def down
    execute <<~SQL
      CREATE OR REPLACE FUNCTION auto_stop_list_on_zero_stock()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NEW.qty <= 0 THEN
          UPDATE product_tenant_settings pts
          SET    is_sold_out      = TRUE,
                 sold_out_reason  = 'stock_empty',
                 updated_at       = NOW()
          FROM   product_recipes pr
          WHERE  pr.ingredient_id = NEW.ingredient_id
            AND  pts.product_id   = pr.product_id
            AND  pts.tenant_id    = NEW.tenant_id
            AND  pts.is_sold_out  = FALSE;
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end
end
