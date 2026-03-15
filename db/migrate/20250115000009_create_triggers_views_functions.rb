class CreateTriggersViewsFunctions < ActiveRecord::Migration[8.1]
  def up
    # Триггер для автоматической генерации order_number
    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_order_number()
      RETURNS TRIGGER AS $$
      DECLARE
        new_sequence BIGINT;
        year_month TEXT;
      BEGIN
        -- Получаем следующий номер последовательности
        SELECT COALESCE(MAX(order_sequence), 0) + 1 INTO new_sequence
        FROM orders
        WHERE tenant_id = NEW.tenant_id
          AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', NOW());
        
        -- Формируем номер: #YYYYMM-####
        year_month := TO_CHAR(NOW(), 'YYYYMM');
        NEW.order_number := '#' || year_month || '-' || LPAD(new_sequence::TEXT, 4, '0');
        NEW.order_sequence := new_sequence;
        
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    execute <<-SQL
      CREATE TRIGGER trg_generate_order_number
      BEFORE INSERT ON orders
      FOR EACH ROW
      WHEN (NEW.order_number IS NULL OR NEW.order_number = '')
      EXECUTE FUNCTION generate_order_number();
    SQL
    
    execute "COMMENT ON FUNCTION generate_order_number() IS 'Автоматическая генерация номера заказа'"
    
    # Триггер для автоматического обновления updated_at
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # Применяем триггер к основным таблицам
    %w[
      tenants users roles orders order_items payments products categories
      devices shifts mobile_customers kiosk_settings
    ].each do |table|
      execute <<-SQL
        CREATE TRIGGER trg_update_#{table}_updated_at
        BEFORE UPDATE ON #{table}
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
      SQL
    end
    
    # Триггер для автоматического списания ингредиентов при подтверждении заказа
    execute <<-SQL
      CREATE OR REPLACE FUNCTION auto_deduct_ingredients_on_order_accept()
      RETURNS TRIGGER AS $$
      DECLARE
        item RECORD;
        recipe RECORD;
        modifier_recipe RECORD;
        qty_needed DECIMAL;
        current_stock RECORD;
      BEGIN
        -- Срабатывает только при переходе в статус 'accepted'
        IF NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status != 'accepted') THEN
          
          -- Проходим по всем позициям заказа
          FOR item IN SELECT * FROM order_items WHERE order_id = NEW.id LOOP
            
            -- Получаем рецептуру продукта
            FOR recipe IN SELECT * FROM product_recipes WHERE product_id = item.product_id LOOP
              
              -- Рассчитываем количество ингредиента на заказ
              qty_needed := recipe.qty_per_serving * item.quantity;
              
              -- Учитываем модификаторы (если есть)
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
              
              -- Проверяем остаток
              SELECT * INTO current_stock
              FROM ingredient_tenant_stocks
              WHERE tenant_id = NEW.tenant_id
                AND ingredient_id = recipe.ingredient_id;
              
              -- Если остатка нет, создаём запись с нулём
              IF current_stock IS NULL THEN
                INSERT INTO ingredient_tenant_stocks (tenant_id, ingredient_id, qty, created_at, updated_at)
                VALUES (NEW.tenant_id, recipe.ingredient_id, 0, NOW(), NOW());
                current_stock.qty := 0;
              END IF;
              
              -- Списываем ингредиент
              UPDATE ingredient_tenant_stocks
              SET qty = qty - qty_needed,
                  last_updated_at = NOW(),
                  updated_at = NOW()
              WHERE tenant_id = NEW.tenant_id
                AND ingredient_id = recipe.ingredient_id;
              
              -- Создаём запись движения (если нужно)
              -- Можно создать stock_movement с типом 'order_deduct'
              
            END LOOP;
          END LOOP;
        END IF;
        
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    execute <<-SQL
      CREATE TRIGGER trg_auto_deduct_ingredients
      AFTER UPDATE ON orders
      FOR EACH ROW
      WHEN (NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status != 'accepted'))
      EXECUTE FUNCTION auto_deduct_ingredients_on_order_accept();
    SQL
    
    execute "COMMENT ON FUNCTION auto_deduct_ingredients_on_order_accept() IS 'Автоматическое списание ингредиентов при принятии заказа'"
    
    # Триггер для автоматического стоп-листа при нулевом остатке
    execute <<-SQL
      CREATE OR REPLACE FUNCTION auto_stop_list_on_zero_stock()
      RETURNS TRIGGER AS $$
      DECLARE
        product_record RECORD;
      BEGIN
        -- Если остаток стал <= 0
        IF NEW.qty <= 0 THEN
          
          -- Находим все продукты, использующие этот ингредиент
          FOR product_record IN
            SELECT DISTINCT pr.product_id
            FROM product_recipes pr
            WHERE pr.ingredient_id = NEW.ingredient_id
          LOOP
            
            -- Устанавливаем стоп-лист для всех точек
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
    
    execute <<-SQL
      CREATE TRIGGER trg_auto_stop_list
      AFTER UPDATE ON ingredient_tenant_stocks
      FOR EACH ROW
      WHEN (NEW.qty <= 0 AND (OLD.qty IS NULL OR OLD.qty > 0))
      EXECUTE FUNCTION auto_stop_list_on_zero_stock();
    SQL
    
    execute "COMMENT ON FUNCTION auto_stop_list_on_zero_stock() IS 'Автоматический стоп-лист при нулевом остатке ингредиента'"
    
    # View: v_active_orders_for_barista
    execute <<-SQL
      CREATE OR REPLACE VIEW v_active_orders_for_barista AS
      SELECT 
        o.id,
        o.tenant_id,
        o.order_number,
        o.status,
        o.source,
        o.created_at,
        o.final_amount,
        COUNT(oi.id) as items_count,
        MAX(osl.created_at) as last_status_change_at
      FROM orders o
      LEFT JOIN order_items oi ON oi.order_id = o.id
      LEFT JOIN order_status_logs osl ON osl.order_id = o.id
      WHERE o.status IN ('accepted', 'preparing', 'ready')
      GROUP BY o.id, o.tenant_id, o.order_number, o.status, o.source, o.created_at, o.final_amount
      ORDER BY 
        CASE o.status
          WHEN 'ready' THEN 1
          WHEN 'preparing' THEN 2
          WHEN 'accepted' THEN 3
        END,
        o.created_at ASC;
    SQL
    
    execute "COMMENT ON VIEW v_active_orders_for_barista IS 'Активные заказы для табло баристы'"
    
    # View: v_kiosk_menu
    execute <<-SQL
      CREATE OR REPLACE VIEW v_kiosk_menu AS
      SELECT 
        p.id as product_id,
        p.name as product_name,
        p.slug as product_slug,
        p.image_url,
        c.id as category_id,
        c.name as category_name,
        c.sort_order as category_sort_order,
        pts.tenant_id,
        pts.price,
        pts.is_enabled,
        pts.is_sold_out,
        pts.sold_out_reason,
        p.sort_order as product_sort_order
      FROM products p
      INNER JOIN categories c ON c.id = p.category_id
      INNER JOIN product_tenant_settings pts ON pts.product_id = p.id
      INNER JOIN product_menu_visibilities pmv ON pmv.product_id = p.id
      INNER JOIN menu_types mt ON mt.id = pmv.menu_type_id AND mt.code = 'kiosk'
      WHERE p.is_active = TRUE
        AND c.is_active = TRUE
        AND pts.is_enabled = TRUE
        AND pts.is_sold_out = FALSE
        AND pmv.is_visible = TRUE
      ORDER BY c.sort_order, p.sort_order;
    SQL
    
    execute "COMMENT ON VIEW v_kiosk_menu IS 'Меню для киоска (только доступные продукты)'"
    
    # Функция: change_order_status
    execute <<-SQL
      CREATE OR REPLACE FUNCTION change_order_status(
        p_order_id UUID,
        p_new_status order_status,
        p_changed_by_user_id UUID DEFAULT NULL,
        p_device_id UUID DEFAULT NULL,
        p_source TEXT DEFAULT 'system',
        p_comment TEXT DEFAULT NULL
      )
      RETURNS UUID AS $$
      DECLARE
        v_old_status order_status;
        v_log_id UUID;
        v_tenant_id UUID;
      BEGIN
        -- Получаем текущий статус и tenant_id
        SELECT status, tenant_id INTO v_old_status, v_tenant_id
        FROM orders
        WHERE id = p_order_id;
        
        IF v_old_status IS NULL THEN
          RAISE EXCEPTION 'Order not found: %', p_order_id;
        END IF;
        
        -- Обновляем статус заказа
        UPDATE orders
        SET status = p_new_status,
            updated_at = NOW()
        WHERE id = p_order_id;
        
        -- Создаём запись в логе
        INSERT INTO order_status_logs (
          id,
          order_id,
          status_from,
          status_to,
          changed_by,
          device_id,
          source,
          comment,
          created_at,
          updated_at
        )
        VALUES (
          gen_random_uuid(),
          p_order_id,
          v_old_status,
          p_new_status,
          p_changed_by_user_id,
          p_device_id,
          p_source,
          p_comment,
          NOW(),
          NOW()
        )
        RETURNING id INTO v_log_id;
        
        RETURN v_log_id;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    execute "COMMENT ON FUNCTION change_order_status(UUID, order_status, UUID, UUID, TEXT, TEXT) IS 'Изменение статуса заказа с логированием'"
    
    # Функция: cancel_order
    execute <<-SQL
      CREATE OR REPLACE FUNCTION cancel_order(
        p_order_id UUID,
        p_cancel_reason_code TEXT,
        p_cancel_reason TEXT DEFAULT NULL,
        p_cancel_stage TEXT DEFAULT NULL,
        p_changed_by_user_id UUID DEFAULT NULL
      )
      RETURNS UUID AS $$
      DECLARE
        v_log_id UUID;
        v_current_status order_status;
      BEGIN
        -- Получаем текущий статус
        SELECT status INTO v_current_status
        FROM orders
        WHERE id = p_order_id;
        
        IF v_current_status IS NULL THEN
          RAISE EXCEPTION 'Order not found: %', p_order_id;
        END IF;
        
        IF v_current_status IN ('issued', 'closed', 'cancelled') THEN
          RAISE EXCEPTION 'Cannot cancel order in status: %', v_current_status;
        END IF;
        
        -- Обновляем заказ
        UPDATE orders
        SET status = 'cancelled',
            cancel_reason_code = p_cancel_reason_code,
            cancel_reason = p_cancel_reason,
            cancel_stage = p_cancel_stage,
            updated_at = NOW()
        WHERE id = p_order_id;
        
        -- Создаём запись в логе
        INSERT INTO order_status_logs (
          id,
          order_id,
          status_from,
          status_to,
          changed_by,
          source,
          comment,
          created_at,
          updated_at
        )
        VALUES (
          gen_random_uuid(),
          p_order_id,
          v_current_status,
          'cancelled',
          p_changed_by_user_id,
          'manual',
          COALESCE(p_cancel_reason, 'Order cancelled'),
          NOW(),
          NOW()
        )
        RETURNING id INTO v_log_id;
        
        RETURN v_log_id;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    execute "COMMENT ON FUNCTION cancel_order(UUID, TEXT, TEXT, TEXT, UUID) IS 'Отмена заказа с указанием причины'"
  end
  
  def down
    execute "DROP FUNCTION IF EXISTS cancel_order(UUID, TEXT, TEXT, TEXT, UUID)"
    execute "DROP FUNCTION IF EXISTS change_order_status(UUID, order_status, UUID, UUID, TEXT, TEXT)"
    execute "DROP VIEW IF EXISTS v_kiosk_menu"
    execute "DROP VIEW IF EXISTS v_active_orders_for_barista"
    execute "DROP FUNCTION IF EXISTS auto_stop_list_on_zero_stock()"
    execute "DROP FUNCTION IF EXISTS auto_deduct_ingredients_on_order_accept()"
    execute "DROP FUNCTION IF EXISTS update_updated_at_column()"
    execute "DROP FUNCTION IF EXISTS generate_order_number()"
    
    # Удаляем триггеры
    %w[
      tenants users roles orders order_items payments products categories
      devices shifts mobile_customers kiosk_settings
    ].each do |table|
      execute "DROP TRIGGER IF EXISTS trg_update_#{table}_updated_at ON #{table}"
    end
    
    execute "DROP TRIGGER IF EXISTS trg_auto_stop_list ON ingredient_tenant_stocks"
    execute "DROP TRIGGER IF EXISTS trg_auto_deduct_ingredients ON orders"
    execute "DROP TRIGGER IF EXISTS trg_generate_order_number ON orders"
  end
end
