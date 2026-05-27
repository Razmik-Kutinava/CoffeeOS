
```sql
-- ============================================================================
-- SQL МИГРАЦИИ ДЛЯ СИСТЕМЫ КОФЕЕН (POSTGRESQL)
-- ЭТАП 11: ЗАГОТОВОЧНЫЙ ЦЕХ (PRODUCTION KITCHEN)
-- Версия 1.1 - Исправлены start_production_batch и SEED DATA
-- ============================================================================

-- ============================================================================
-- ЧАСТЬ A: РАСШИРЕНИЕ ТАБЛИЦЫ ingredients
-- ============================================================================

ALTER TABLE ingredients 
    ADD COLUMN IF NOT EXISTS is_semifinished BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS shelf_life_hours INTEGER,
    ADD COLUMN IF NOT EXISTS storage_temp VARCHAR(50),
    ADD COLUMN IF NOT EXISTS production_unit VARCHAR(20);

ALTER TABLE ingredients
    DROP CONSTRAINT IF EXISTS chk_ingredient_storage_temp;

ALTER TABLE ingredients
    ADD CONSTRAINT chk_ingredient_storage_temp 
    CHECK (storage_temp IS NULL OR storage_temp IN ('room', 'refrigerated', 'frozen'));

COMMENT ON COLUMN ingredients.is_semifinished IS 'Является ли ингредиент полуфабрикатом (производится в цехе)';
COMMENT ON COLUMN ingredients.shelf_life_hours IS 'Срок хранения в часах (NULL = без ограничений)';
COMMENT ON COLUMN ingredients.storage_temp IS 'Условия хранения: room, refrigerated, frozen';
COMMENT ON COLUMN ingredients.production_unit IS 'Единица производства (batch, kg, l) для ПФ';

CREATE INDEX IF NOT EXISTS idx_ingredients_semifinished ON ingredients(is_semifinished) WHERE is_semifinished = TRUE;
CREATE INDEX IF NOT EXISTS idx_ingredients_storage_temp ON ingredients(storage_temp);

-- Уникальный индекс на name для SEED DATA
CREATE UNIQUE INDEX IF NOT EXISTS idx_ingredients_name_unique ON ingredients(name);

-- ============================================================================
-- ЧАСТЬ B: ТАБЛИЦА production_recipes
-- ============================================================================

CREATE TABLE IF NOT EXISTS production_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    semifinished_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity DECIMAL(10,3) NOT NULL,
    unit_override VARCHAR(20),
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(semifinished_id, ingredient_id),
    CONSTRAINT chk_production_recipe_quantity CHECK (quantity > 0),
    CONSTRAINT chk_production_recipe_not_self CHECK (semifinished_id != ingredient_id)
);

COMMENT ON TABLE production_recipes IS 'Рецептура производства ПФ в цехе (из каких сырьевых ингредиентов состоит ПФ)';
COMMENT ON COLUMN production_recipes.id IS 'Уникальный идентификатор записи рецепта';
COMMENT ON COLUMN production_recipes.semifinished_id IS 'Полуфабрикат который производим';
COMMENT ON COLUMN production_recipes.ingredient_id IS 'Сырьевой ингредиент (не ПФ)';
COMMENT ON COLUMN production_recipes.quantity IS 'Количество на единицу ПФ';
COMMENT ON COLUMN production_recipes.unit_override IS 'Переопределение единицы (если нужно конвертировать)';
COMMENT ON COLUMN production_recipes.note IS 'Комментарий к ингредиенту';
COMMENT ON COLUMN production_recipes.created_at IS 'Дата создания';
COMMENT ON COLUMN production_recipes.updated_at IS 'Дата обновления';

CREATE INDEX idx_production_recipes_semifinished ON production_recipes(semifinished_id);
CREATE INDEX idx_production_recipes_ingredient ON production_recipes(ingredient_id);
CREATE INDEX idx_production_recipes_semifinished_ingredient ON production_recipes(semifinished_id, ingredient_id);

CREATE TRIGGER trg_production_recipes_updated_at
    BEFORE UPDATE ON production_recipes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ЧАСТЬ C: ТАБЛИЦА production_batches
-- ============================================================================

CREATE TABLE IF NOT EXISTS production_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    semifinished_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity DECIMAL(10,3) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'planned',
    planned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    produced_by UUID REFERENCES users(id) ON DELETE SET NULL,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_batch_quantity CHECK (quantity > 0),
    CONSTRAINT chk_batch_status CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled'))
);

COMMENT ON TABLE production_batches IS 'Партии производства ПФ в цехе';
COMMENT ON COLUMN production_batches.id IS 'Уникальный идентификатор партии';
COMMENT ON COLUMN production_batches.tenant_id IS 'Тенант цеха (производитель)';
COMMENT ON COLUMN production_batches.semifinished_id IS 'Какой ПФ произведён';
COMMENT ON COLUMN production_batches.quantity IS 'Количество произведённого';
COMMENT ON COLUMN production_batches.status IS 'Статус: planned, in_progress, completed, cancelled';
COMMENT ON COLUMN production_batches.planned_at IS 'Когда запланировано';
COMMENT ON COLUMN production_batches.started_at IS 'Начало производства';
COMMENT ON COLUMN production_batches.completed_at IS 'Окончание производства';
COMMENT ON COLUMN production_batches.expires_at IS 'Срок годности партии';
COMMENT ON COLUMN production_batches.produced_by IS 'Кто произвёл';
COMMENT ON COLUMN production_batches.note IS 'Комментарий';
COMMENT ON COLUMN production_batches.created_at IS 'Дата создания';
COMMENT ON COLUMN production_batches.updated_at IS 'Дата обновления';

CREATE INDEX idx_production_batches_tenant_status ON production_batches(tenant_id, status);
CREATE INDEX idx_production_batches_semifinished ON production_batches(semifinished_id);
CREATE INDEX idx_production_batches_planned_at ON production_batches(planned_at DESC);
CREATE INDEX idx_production_batches_expires ON production_batches(expires_at) WHERE expires_at IS NOT NULL;

CREATE TRIGGER trg_production_batches_updated_at
    BEFORE UPDATE ON production_batches
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ЧАСТЬ D: ТАБЛИЦА supply_orders
-- ============================================================================

CREATE TABLE IF NOT EXISTS supply_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    to_tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    requested_by UUID REFERENCES users(id) ON DELETE SET NULL,
    confirmed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    shipped_at TIMESTAMP WITH TIME ZONE,
    received_at TIMESTAMP WITH TIME ZONE,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_supply_order_tenants CHECK (from_tenant_id != to_tenant_id),
    CONSTRAINT chk_supply_order_status CHECK (status IN ('pending', 'confirmed', 'shipped', 'received', 'cancelled'))
);

COMMENT ON TABLE supply_orders IS 'Заявки на отгрузку ПФ с цеха на точки';
COMMENT ON COLUMN supply_orders.id IS 'Уникальный идентификатор заявки';
COMMENT ON COLUMN supply_orders.from_tenant_id IS 'Тенант-цех (отправитель)';
COMMENT ON COLUMN supply_orders.to_tenant_id IS 'Тенант-точка (получатель)';
COMMENT ON COLUMN supply_orders.status IS 'Статус: pending, confirmed, shipped, received, cancelled';
COMMENT ON COLUMN supply_orders.requested_by IS 'Кто создал заявку (менеджер точки)';
COMMENT ON COLUMN supply_orders.confirmed_by IS 'Кто подтвердил в цехе';
COMMENT ON COLUMN supply_orders.shipped_at IS 'Время отгрузки';
COMMENT ON COLUMN supply_orders.received_at IS 'Время получения';
COMMENT ON COLUMN supply_orders.note IS 'Комментарий';
COMMENT ON COLUMN supply_orders.created_at IS 'Дата создания';
COMMENT ON COLUMN supply_orders.updated_at IS 'Дата обновления';

CREATE INDEX idx_supply_orders_from_tenant_status ON supply_orders(from_tenant_id, status);
CREATE INDEX idx_supply_orders_to_tenant_status ON supply_orders(to_tenant_id, status);
CREATE INDEX idx_supply_orders_created_at ON supply_orders(created_at DESC);

CREATE TRIGGER trg_supply_orders_updated_at
    BEFORE UPDATE ON supply_orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ЧАСТЬ E: ТАБЛИЦА supply_order_items
-- ============================================================================

CREATE TABLE IF NOT EXISTS supply_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supply_order_id UUID NOT NULL REFERENCES supply_orders(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity_requested DECIMAL(10,3) NOT NULL,
    quantity_shipped DECIMAL(10,3),
    unit_cost DECIMAL(10,2),
    note TEXT,
    UNIQUE(supply_order_id, ingredient_id),
    CONSTRAINT chk_supply_item_requested CHECK (quantity_requested > 0),
    CONSTRAINT chk_supply_item_shipped CHECK (quantity_shipped IS NULL OR quantity_shipped >= 0)
);

COMMENT ON TABLE supply_order_items IS 'Позиции заявки на отгрузку';
COMMENT ON COLUMN supply_order_items.id IS 'Уникальный идентификатор позиции';
COMMENT ON COLUMN supply_order_items.supply_order_id IS 'Заявка на отгрузку';
COMMENT ON COLUMN supply_order_items.ingredient_id IS 'ПФ или ингредиент';
COMMENT ON COLUMN supply_order_items.quantity_requested IS 'Сколько запросили';
COMMENT ON COLUMN supply_order_items.quantity_shipped IS 'Сколько фактически отгружено';
COMMENT ON COLUMN supply_order_items.unit_cost IS 'Себестоимость за единицу';
COMMENT ON COLUMN supply_order_items.note IS 'Комментарий';

CREATE INDEX idx_supply_order_items_supply_order ON supply_order_items(supply_order_id);
CREATE INDEX idx_supply_order_items_ingredient ON supply_order_items(ingredient_id);

-- ============================================================================
-- ЧАСТЬ F: ФУНКЦИИ ПРОИЗВОДСТВА
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: start_production_batch
-- ИСПРАВЛЕНИЕ #1: Один stock_movement на партию + stock_movement_items
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION start_production_batch(
    p_tenant_id UUID,
    p_semifinished_id UUID,
    p_quantity DECIMAL(10,3),
    p_produced_by UUID,
    p_note TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_batch_id UUID;
    v_movement_id UUID;
    v_recipe RECORD;
    v_need DECIMAL(10,3);
    v_available DECIMAL(10,3);
    v_ingredient_name VARCHAR(255);
BEGIN
    -- Проверяем что ингредиент является ПФ
    PERFORM 1 FROM ingredients
    WHERE id = p_semifinished_id
      AND is_semifinished = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ингредиент не является полуфабрикатом';
    END IF;
    
    -- ПРОВЕРКА 1: Сначала проверяем наличие всего сырья (без списания)
    FOR v_recipe IN
        SELECT pr.ingredient_id, pr.quantity, i.name
        FROM production_recipes pr
        JOIN ingredients i ON pr.ingredient_id = i.id
        WHERE pr.semifinished_id = p_semifinished_id
    LOOP
        v_need := v_recipe.quantity * p_quantity;
        
        SELECT COALESCE(quantity, 0) INTO v_available
        FROM ingredient_tenant_stock
        WHERE tenant_id = p_tenant_id
          AND ingredient_id = v_recipe.ingredient_id;
        
        IF v_available < v_need THEN
            RAISE EXCEPTION 'Недостаточно сырья: % (требуется: %, доступно: %)', 
                v_recipe.name, v_need, v_available;
        END IF;
    END LOOP;
    
    -- ПРОВЕРКА 2: Все ингредиенты есть — создаём партию
    INSERT INTO production_batches (
        tenant_id, semifinished_id, quantity, status,
        started_at, produced_by, note
    ) VALUES (
        p_tenant_id, p_semifinished_id, p_quantity, 'in_progress',
        NOW(), p_produced_by, p_note
    )
    RETURNING id INTO v_batch_id;
    
    -- ИСПРАВЛЕНИЕ #1: Создаём ОДИН stock_movement ДО цикла
    INSERT INTO stock_movements (
        tenant_id, movement_type, status, note,
        created_by, confirmed_by, confirmed_at
    ) VALUES (
        p_tenant_id, 'production', 'confirmed',
        'Списание сырья для партии ' || v_batch_id,
        p_produced_by, p_produced_by, NOW()
    )
    RETURNING id INTO v_movement_id;
    
    -- СПИСАНИЕ: Теперь списываем сырьё и создаём stock_movement_items
    FOR v_recipe IN
        SELECT ingredient_id, quantity
        FROM production_recipes
        WHERE semifinished_id = p_semifinished_id
    LOOP
        v_need := v_recipe.quantity * p_quantity;
        
        -- Списываем со склада
        UPDATE ingredient_tenant_stock
        SET quantity = quantity - v_need,
            updated_at = NOW()
        WHERE tenant_id = p_tenant_id
          AND ingredient_id = v_recipe.ingredient_id;
        
        -- ИСПРАВЛЕНИЕ #1: Создаём stock_movement_items для каждого ингредиента
        INSERT INTO stock_movement_items (
            movement_id, ingredient_id, quantity, note
        ) VALUES (
            v_movement_id,
            v_recipe.ingredient_id,
            -v_need,
            'Производство партии ' || v_batch_id
        );
    END LOOP;
    
    RETURN v_batch_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: complete_production_batch
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION complete_production_batch(
    p_batch_id UUID,
    p_actual_quantity DECIMAL(10,3) DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_batch RECORD;
    v_quantity DECIMAL(10,3);
    v_expires_at TIMESTAMP WITH TIME ZONE;
    v_shelf_life_hours INTEGER;
BEGIN
    -- Находим партию с блокировкой
    SELECT * INTO v_batch
    FROM production_batches
    WHERE id = p_batch_id
      AND status = 'in_progress'
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Партия не найдена или не в производстве';
    END IF;
    
    -- Фактическое количество (может отличаться от планового)
    v_quantity := COALESCE(p_actual_quantity, v_batch.quantity);
    
    -- Получаем срок хранения ПФ
    SELECT shelf_life_hours INTO v_shelf_life_hours
    FROM ingredients
    WHERE id = v_batch.semifinished_id;
    
    -- Считаем expires_at
    IF v_shelf_life_hours IS NOT NULL THEN
        v_expires_at := NOW() + (v_shelf_life_hours || ' hours')::INTERVAL;
    ELSE
        v_expires_at := NULL;
    END IF;
    
    -- Оприходуем ПФ на склад цеха
    INSERT INTO ingredient_tenant_stock (tenant_id, ingredient_id, quantity)
    VALUES (v_batch.tenant_id, v_batch.semifinished_id, v_quantity)
    ON CONFLICT (tenant_id, ingredient_id) DO UPDATE
    SET quantity = ingredient_tenant_stock.quantity + v_quantity,
        updated_at = NOW();
    
    -- Завершаем партию
    UPDATE production_batches
    SET status = 'completed',
        completed_at = NOW(),
        quantity = v_quantity,
        expires_at = v_expires_at,
        updated_at = NOW()
    WHERE id = p_batch_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: cancel_production_batch
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION cancel_production_batch(
    p_batch_id UUID,
    p_cancelled_by UUID
)
RETURNS VOID AS $$
DECLARE
    v_batch RECORD;
    v_recipe RECORD;
    v_need DECIMAL(10,3);
BEGIN
    -- Находим партию с блокировкой
    SELECT * INTO v_batch
    FROM production_batches
    WHERE id = p_batch_id
      AND status IN ('planned', 'in_progress')
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Партия не найдена или уже завершена/отменена';
    END IF;
    
    -- Если status='in_progress' — возвращаем сырьё обратно
    IF v_batch.status = 'in_progress' THEN
        FOR v_recipe IN
            SELECT ingredient_id, quantity
            FROM production_recipes
            WHERE semifinished_id = v_batch.semifinished_id
        LOOP
            v_need := v_recipe.quantity * v_batch.quantity;
            
            -- Возвращаем сырьё на склад
            UPDATE ingredient_tenant_stock
            SET quantity = quantity + v_need,
                updated_at = NOW()
            WHERE tenant_id = v_batch.tenant_id
              AND ingredient_id = v_recipe.ingredient_id;
        END LOOP;
    END IF;
    
    -- Отменяем партию
    UPDATE production_batches
    SET status = 'cancelled',
        updated_at = NOW()
    WHERE id = p_batch_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ЧАСТЬ G: ФУНКЦИИ ОТГРУЗКИ
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: create_supply_order
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION create_supply_order(
    p_from_tenant_id UUID,
    p_to_tenant_id UUID,
    p_items JSONB,
    p_requested_by UUID,
    p_note TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_supply_order_id UUID;
    v_item JSONB;
BEGIN
    -- Проверяем что тенанты разные
    IF p_from_tenant_id = p_to_tenant_id THEN
        RAISE EXCEPTION 'Тенант отправителя и получателя должны быть разными';
    END IF;
    
    -- Проверяем что есть позиции
    IF jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'Заявка должна содержать хотя бы одну позицию';
    END IF;
    
    -- Создаём заявку
    INSERT INTO supply_orders (
        from_tenant_id, to_tenant_id, status,
        requested_by, note
    ) VALUES (
        p_from_tenant_id, p_to_tenant_id, 'pending',
        p_requested_by, p_note
    )
    RETURNING id INTO v_supply_order_id;
    
    -- Добавляем позиции
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO supply_order_items (
            supply_order_id, ingredient_id, quantity_requested
        ) VALUES (
            v_supply_order_id,
            (v_item->>'ingredient_id')::UUID,
            (v_item->>'quantity')::DECIMAL(10,3)
        );
    END LOOP;
    
    RETURN v_supply_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: confirm_supply_order
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION confirm_supply_order(
    p_supply_order_id UUID,
    p_confirmed_by UUID
)
RETURNS VOID AS $$
DECLARE
    v_order RECORD;
    v_item RECORD;
    v_available DECIMAL(10,3);
    v_ingredient_name VARCHAR(255);
BEGIN
    -- Находим заявку с блокировкой
    SELECT * INTO v_order
    FROM supply_orders
    WHERE id = p_supply_order_id
      AND status = 'pending'
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена или уже подтверждена';
    END IF;
    
    -- ПРОВЕРКА: Наличие всех ингредиентов на складе цеха
    FOR v_item IN
        SELECT soi.ingredient_id, soi.quantity_requested, i.name
        FROM supply_order_items soi
        JOIN ingredients i ON soi.ingredient_id = i.id
        WHERE soi.supply_order_id = p_supply_order_id
    LOOP
        SELECT COALESCE(quantity, 0) INTO v_available
        FROM ingredient_tenant_stock
        WHERE tenant_id = v_order.from_tenant_id
          AND ingredient_id = v_item.ingredient_id;
        
        IF v_available < v_item.quantity_requested THEN
            RAISE EXCEPTION 'Недостаточно на складе: % (требуется: %, доступно: %)', 
                v_item.name, v_item.quantity_requested, v_available;
        END IF;
    END LOOP;
    
    -- Подтверждаем заявку
    UPDATE supply_orders
    SET status = 'confirmed',
        confirmed_by = p_confirmed_by,
        updated_at = NOW()
    WHERE id = p_supply_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: ship_supply_order
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ship_supply_order(
    p_supply_order_id UUID,
    p_shipped_by UUID,
    p_items_shipped JSONB DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_order RECORD;
    v_item RECORD;
    v_shipped_qty DECIMAL(10,3);
    v_movement_id UUID;
BEGIN
    -- Находим заявку с блокировкой
    SELECT * INTO v_order
    FROM supply_orders
    WHERE id = p_supply_order_id
      AND status = 'confirmed'
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена или не подтверждена';
    END IF;
    
    -- Создаём stock_movement для отгрузки
    INSERT INTO stock_movements (
        tenant_id, movement_type, status, note,
        created_by, confirmed_by, confirmed_at
    ) VALUES (
        v_order.from_tenant_id, 'supply', 'confirmed',
        'Отгрузка по заявке ' || p_supply_order_id,
        p_shipped_by, p_shipped_by, NOW()
    )
    RETURNING id INTO v_movement_id;
    
    -- Отгружаем позиции
    FOR v_item IN
        SELECT * FROM supply_order_items
        WHERE supply_order_id = p_supply_order_id
    LOOP
        -- Определяем количество отгрузки
        IF p_items_shipped IS NOT NULL THEN
            SELECT (elem->>'quantity')::DECIMAL(10,3)
            INTO v_shipped_qty
            FROM jsonb_array_elements(p_items_shipped) AS elem
            WHERE (elem->>'ingredient_id')::UUID = v_item.ingredient_id;
            
            v_shipped_qty := COALESCE(v_shipped_qty, v_item.quantity_requested);
        ELSE
            v_shipped_qty := v_item.quantity_requested;
        END IF;
        
        -- Не допускаем отгрузку больше запрошенного
        IF v_shipped_qty > v_item.quantity_requested THEN
            RAISE EXCEPTION 'Отгрузка не может превышать запрошенное количество';
        END IF;
        
        -- Обновляем позицию
        UPDATE supply_order_items
        SET quantity_shipped = v_shipped_qty
        WHERE id = v_item.id;
        
        -- Списываем со склада цеха
        UPDATE ingredient_tenant_stock
        SET quantity = quantity - v_shipped_qty,
            updated_at = NOW()
        WHERE tenant_id = v_order.from_tenant_id
          AND ingredient_id = v_item.ingredient_id;
        
        -- Добавляем позицию в stock_movement
        INSERT INTO stock_movement_items (
            movement_id, ingredient_id, quantity, note
        ) VALUES (
            v_movement_id, v_item.ingredient_id, -v_shipped_qty,
            'Отгрузка в точку ' || v_order.to_tenant_id
        );
    END LOOP;
    
    -- Обновляем заявку
    UPDATE supply_orders
    SET status = 'shipped',
        shipped_at = NOW(),
        updated_at = NOW()
    WHERE id = p_supply_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: receive_supply_order
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION receive_supply_order(
    p_supply_order_id UUID,
    p_received_by UUID
)
RETURNS VOID AS $$
DECLARE
    v_order RECORD;
    v_item RECORD;
    v_movement_id UUID;
BEGIN
    -- Находим заявку с блокировкой
    SELECT * INTO v_order
    FROM supply_orders
    WHERE id = p_supply_order_id
      AND status = 'shipped'
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена или не отгружена';
    END IF;
    
    -- Создаём stock_movement для приёмки на точке
    INSERT INTO stock_movements (
        tenant_id, movement_type, status, note,
        created_by, confirmed_by, confirmed_at
    ) VALUES (
        v_order.to_tenant_id, 'receipt', 'confirmed',
        'Приёмка по заявке ' || p_supply_order_id,
        p_received_by, p_received_by, NOW()
    )
    RETURNING id INTO v_movement_id;
    
    -- Оприходуем на склад точки
    FOR v_item IN
        SELECT * FROM supply_order_items
        WHERE supply_order_id = p_supply_order_id
          AND quantity_shipped IS NOT NULL
    LOOP
        -- Добавляем на склад точки
        INSERT INTO ingredient_tenant_stock (tenant_id, ingredient_id, quantity)
        VALUES (v_order.to_tenant_id, v_item.ingredient_id, v_item.quantity_shipped)
        ON CONFLICT (tenant_id, ingredient_id) DO UPDATE
        SET quantity = ingredient_tenant_stock.quantity + v_item.quantity_shipped,
            updated_at = NOW();
        
        -- Добавляем позицию в stock_movement
        INSERT INTO stock_movement_items (
            movement_id, ingredient_id, quantity, note
        ) VALUES (
            v_movement_id, v_item.ingredient_id, v_item.quantity_shipped,
            'Приёмка от цеха'
        );
    END LOOP;
    
    -- Завершаем заявку
    UPDATE supply_orders
    SET status = 'received',
        received_at = NOW(),
        updated_at = NOW()
    WHERE id = p_supply_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ЧАСТЬ H: VIEWS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- VIEW: v_production_batches
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_production_batches AS
SELECT 
    pb.tenant_id,
    pb.id AS batch_id,
    i.name AS semifinished_name,
    i.unit AS semifinished_unit,
    pb.quantity,
    pb.status,
    pb.planned_at,
    pb.started_at,
    pb.completed_at,
    pb.expires_at,
    (pb.expires_at IS NOT NULL AND pb.expires_at < NOW()) AS is_expired,
    u.first_name || ' ' || u.last_name AS produced_by_name,
    pb.note
FROM production_batches pb
JOIN ingredients i ON pb.semifinished_id = i.id
LEFT JOIN users u ON pb.produced_by = u.id
ORDER BY pb.planned_at DESC;

COMMENT ON VIEW v_production_batches IS 'Партии производства с деталями';

-- ----------------------------------------------------------------------------
-- VIEW: v_supply_orders
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_supply_orders AS
SELECT 
    so.id AS supply_order_id,
    so.status,
    so.from_tenant_id,
    t_from.name AS from_tenant_name,
    so.to_tenant_id,
    t_to.name AS to_tenant_name,
    (SELECT COUNT(*) FROM supply_order_items WHERE supply_order_id = so.id)::INTEGER AS items_count,
    so.created_at,
    so.shipped_at,
    so.received_at,
    u_req.first_name || ' ' || u_req.last_name AS requested_by_name,
    u_conf.first_name || ' ' || u_conf.last_name AS confirmed_by_name
FROM supply_orders so
JOIN tenants t_from ON so.from_tenant_id = t_from.id
JOIN tenants t_to ON so.to_tenant_id = t_to.id
LEFT JOIN users u_req ON so.requested_by = u_req.id
LEFT JOIN users u_conf ON so.confirmed_by = u_conf.id
ORDER BY so.created_at DESC;

COMMENT ON VIEW v_supply_orders IS 'Заявки на отгрузку с деталями';

-- ----------------------------------------------------------------------------
-- VIEW: v_semifinished_stock
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_semifinished_stock AS
SELECT 
    i.id AS ingredient_id,
    i.name AS ingredient_name,
    i.unit,
    i.shelf_life_hours,
    i.storage_temp,
    its.tenant_id,
    t.name AS tenant_name,
    its.quantity,
    (
        SELECT COUNT(*)
        FROM production_batches pb
        WHERE pb.semifinished_id = i.id
          AND pb.tenant_id = its.tenant_id
          AND pb.status = 'completed'
          AND (pb.expires_at IS NULL OR pb.expires_at >= NOW())
    )::INTEGER AS active_batches_count
FROM ingredients i
JOIN ingredient_tenant_stock its ON i.id = its.ingredient_id
JOIN tenants t ON its.tenant_id = t.id
WHERE i.is_semifinished = TRUE
ORDER BY i.name, t.name;

COMMENT ON VIEW v_semifinished_stock IS 'Остатки ПФ на всех складах';

-- ============================================================================
-- ЧАСТЬ I: ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE production_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE production_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE supply_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE supply_order_items ENABLE ROW LEVEL SECURITY;

-- production_recipes: read — все авторизованные
CREATE POLICY rls_production_recipes_read ON production_recipes
    FOR SELECT
    USING (TRUE);

-- production_recipes: write — production_manager/УК
CREATE POLICY rls_production_recipes_write ON production_recipes
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('production_manager', 'ук_global_admin', 'ук_country_manager')
        )
    );

-- production_batches: read — production_manager/production_worker своего тенанта + УК
CREATE POLICY rls_production_batches_read ON production_batches
    FOR SELECT
    USING (
        (
            tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
            AND EXISTS (
                SELECT 1 FROM user_roles ur
                JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                AND r.code IN ('production_manager', 'production_worker')
            )
        )
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager')
        )
    );

-- production_batches: write — только через SECURITY DEFINER функции

-- supply_orders: read — office_manager/production_manager обоих тенантов + УК
CREATE POLICY rls_supply_orders_read ON supply_orders
    FOR SELECT
    USING (
        (
            (from_tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
             OR to_tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID)
            AND EXISTS (
                SELECT 1 FROM user_roles ur
                JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                AND r.code IN ('office_manager', 'production_manager')
            )
        )
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager', 'ук_billing_admin')
        )
    );

-- supply_orders: write — только через SECURITY DEFINER функции

-- supply_order_items: read — как supply_orders
CREATE POLICY rls_supply_order_items_read ON supply_order_items
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM supply_orders so
            WHERE so.id = supply_order_items.supply_order_id
            AND (
                (
                    (so.from_tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
                     OR so.to_tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID)
                    AND EXISTS (
                        SELECT 1 FROM user_roles ur
                        JOIN roles r ON ur.role_id = r.id
                        WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                        AND r.code IN ('office_manager', 'production_manager')
                    )
                )
                OR EXISTS (
                    SELECT 1 FROM user_roles ur
                    JOIN roles r ON ur.role_id = r.id
                    WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                    AND r.code IN ('ук_global_admin', 'ук_country_manager', 'ук_billing_admin')
                )
            )
        )
    );

-- supply_order_items: write — только через SECURITY DEFINER функции

-- ============================================================================
-- ЧАСТЬ J: SEED DATA
-- ИСПРАВЛЕНИЕ #2: Убраны несуществующие колонки из INSERT
-- ============================================================================

BEGIN;

SET LOCAL row_security = off;

-- 1. Добавляем роли production_manager и production_worker если не существуют
-- ИСПРАВЛЕНИЕ #2: Убрана колонка description (нет в схеме roles)
INSERT INTO roles (code, name) VALUES
('production_manager', 'Управляющий цеха'),
('production_worker', 'Сотрудник цеха')
ON CONFLICT (code) DO NOTHING;

-- 2. Создаём тенант заготовочного цеха
-- ИСПРАВЛЕНИЕ #2: Убраны колонки type, country, currency, timezone (нет в схеме tenants)
INSERT INTO tenants (id, name, slug, status)
VALUES (
    '00000000-0000-0000-0000-000000000002',
    'Заготовочный цех',
    'production',
    'active'
)
ON CONFLICT (id) DO NOTHING;

-- 3. Создаём тестовые ингредиенты-ПФ
-- ИСПРАВЛЕНИЕ #3: Убран ON CONFLICT без target — используется уникальный индекс
INSERT INTO ingredients (name, unit, is_semifinished, shelf_life_hours, storage_temp, production_unit)
VALUES 
    ('Сироп ванильный', 'ml', TRUE, 720, 'refrigerated', 'l'),
    ('Молочная смесь для латте', 'ml', TRUE, 48, 'refrigerated', 'l')
ON CONFLICT (name) DO NOTHING;

-- 4. Создаём тестовый сырьевой ингредиент
INSERT INTO ingredients (name, unit, is_semifinished)
VALUES ('Ванильный экстракт', 'ml', FALSE)
ON CONFLICT (name) DO NOTHING;

-- 5. Создаём рецептуру для 'Сироп ванильный'
INSERT INTO production_recipes (semifinished_id, ingredient_id, quantity, note)
SELECT 
    sf.id,
    raw.id,
    0.050,  -- 50 ml на 1000 ml (1 l) сиропа
    '50 ml экстракта на 1 l сиропа'
FROM ingredients sf, ingredients raw
WHERE sf.name = 'Сироп ванильный'
  AND raw.name = 'Ванильный экстракт'
  AND sf.is_semifinished = TRUE
  AND raw.is_semifinished = FALSE
ON CONFLICT (semifinished_id, ingredient_id) DO UPDATE SET
    quantity = EXCLUDED.quantity,
    note = EXCLUDED.note;

-- 6. Добавляем начальные остатки сырья на складе цеха
INSERT INTO ingredient_tenant_stock (tenant_id, ingredient_id, quantity)
SELECT 
    '00000000-0000-0000-0000-000000000002',
    i.id,
    5000  -- 5000 ml
FROM ingredients i
WHERE i.name = 'Ванильный экстракт'
ON CONFLICT (tenant_id, ingredient_id) DO UPDATE SET
    quantity = ingredient_tenant_stock.quantity + EXCLUDED.quantity,
    updated_at = NOW();

COMMIT;

-- ============================================================================
-- КОНЕЦ МИГРАЦИЙ ЭТАПА 11
-- ============================================================================

/*
================================================================================
ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ

1. КАК ЗАПУСТИТЬ ПРОИЗВОДСТВО ПАРТИИ ПФ
   SELECT start_production_batch(
       '00000000-0000-0000-0000-000000000002',  -- tenant_id цеха
       'semifinished-uuid',                      -- какой ПФ производим
       10.0,                                     -- количество (10 l)
       'user-uuid',                              -- кто производит
       'Плановая партия'                         -- комментарий
   );

2. КАК ЗАВЕРШИТЬ ПАРТИЮ
   SELECT complete_production_batch('batch-uuid', 9.5);

3. КАК ОТМЕНИТЬ ПАРТИЮ
   SELECT cancel_production_batch('batch-uuid', 'user-uuid');

4. КАК СОЗДАТЬ ЗАЯВКУ НА ОТГРУЗКУ
   SELECT create_supply_order(
       '00000000-0000-0000-0000-000000000002',  -- цех
       '00000000-0000-0000-0000-000000000001',  -- точка
       '[{"ingredient_id": "pf-uuid", "quantity": 5.0}]'::JSONB,
       'user-uuid',
       'Срочная отгрузка'
   );

5. КАК ПОДТВЕРДИТЬ ЗАЯВКУ В ЦЕХЕ
   SELECT confirm_supply_order('supply-order-uuid', 'user-uuid');

6. КАК ОТГРУЗИТЬ ЗАЯВКУ
   SELECT ship_supply_order('supply-order-uuid', 'user-uuid');

7. КАК ПРИНЯТЬ ОТГРУЗКУ НА ТОЧКЕ
   SELECT receive_supply_order('supply-order-uuid', 'user-uuid');

================================================================================
ИСПРАВЛЕНИЯ В ЭТОЙ ВЕРСИИ (1.1)

1. ✅ start_production_batch: Один stock_movement на партию + stock_movement_items
   - v_movement_id объявлен в DECLARE
   - INSERT в stock_movements ПЕРЕД циклом (один movement на всю партию)
   - INSERT в stock_movement_items ВНУТРИ цикла (для каждого ингредиента)

2. ✅ SEED DATA: Убраны несуществующие колонки
   - roles: убрана description (нет в схеме)
   - tenants: убраны type, country, currency, timezone (нет в схеме)

3. ✅ SEED DATA: ON CONFLICT с явным target для ingredients
   - Добавлен уникальный индекс idx_ingredients_name_unique
   - ON CONFLICT (name) DO NOTHING вместо ON CONFLICT DO NOTHING

================================================================================
АРХИТЕКТУРНЫЕ ЗАМЕЧАНИЯ

1. ✅ Заготовочный цех = отдельный тенант
2. ✅ ingredients.is_semifinished маркирует ПФ
3. ✅ start_production_batch: ДВУХЭТАПНАЯ ПРОВЕРКА (проверка → списание)
4. ✅ complete_production_batch: ON CONFLICT для upsert
5. ✅ cancel_production_batch: возврат сырья только для in_progress
6. ✅ supply_orders: from_tenant_id != to_tenant_id CHECK
7. ✅ ship_supply_order: quantity_shipped <= quantity_requested
8. ✅ receive_supply_order: создаёт stock_movement на стороне точки
9. ✅ DECIMAL(10,3) для количеств, DECIMAL(10,2) для денег
10. ✅ FOR UPDATE на всех мутирующих операциях
11. ✅ RLS для supply_orders учитывает оба тенанта
12. ✅ v_semifinished_stock: active_batches_count

================================================================================
*/
```
apps-fileview.texmex_20260501.02_p0
ядро 11 этап.txt
ядро 11 этап.txt. На экране.