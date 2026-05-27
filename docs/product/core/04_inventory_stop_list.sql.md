
```sql
-- ============================================================================
-- SQL МИГРАЦИИ ДЛЯ СИСТЕМЫ КОФЕЕН (POSTGRESQL)
-- ЭТАП 5: СКЛАД ПФ + СТОП-ЛИСТ
-- Версия 5.3 - Исправлено накопление модификаторов (v_single_mod_qty)
-- ============================================================================

-- ============================================================================
-- TABLE: ingredients (глобальный справочник ингредиентов)
-- ============================================================================

CREATE TABLE IF NOT EXISTS ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    category VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_ingredient_unit CHECK (unit IN ('g', 'ml', 'pcs'))
);

COMMENT ON TABLE ingredients IS 'Глобальный справочник ингредиентов (создаёт УК)';
COMMENT ON COLUMN ingredients.id IS 'Уникальный идентификатор ингредиента';
COMMENT ON COLUMN ingredients.name IS 'Название ингредиента';
COMMENT ON COLUMN ingredients.unit IS 'Единица измерения: g=граммы, ml=миллилитры, pcs=штуки';
COMMENT ON COLUMN ingredients.category IS 'Категория для группировки: coffee, milk, syrup, cup, packaging';
COMMENT ON COLUMN ingredients.is_active IS 'Статус активности ингредиента';
COMMENT ON COLUMN ingredients.created_by IS 'Пользователь УК создавший ингредиент';

CREATE INDEX idx_ingredients_name ON ingredients(name);
CREATE INDEX idx_ingredients_unit ON ingredients(unit);
CREATE INDEX idx_ingredients_category ON ingredients(category);
CREATE INDEX idx_ingredients_active ON ingredients(is_active);

-- ============================================================================
-- TABLE: ingredient_tenant_stock (остатки ингредиентов на точке)
-- ============================================================================

CREATE TABLE IF NOT EXISTS ingredient_tenant_stock (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    qty DECIMAL(10,3) NOT NULL DEFAULT 0,
    min_qty DECIMAL(10,3) DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, ingredient_id),
    CONSTRAINT chk_stock_qty CHECK (qty >= 0),
    CONSTRAINT chk_min_qty CHECK (min_qty >= 0)
);

COMMENT ON TABLE ingredient_tenant_stock IS 'Остатки ингредиентов на точке (партнёр управляет)';
COMMENT ON COLUMN ingredient_tenant_stock.id IS 'Уникальный идентификатор записи об остатке';
COMMENT ON COLUMN ingredient_tenant_stock.tenant_id IS 'Тенант (точка продаж)';
COMMENT ON COLUMN ingredient_tenant_stock.ingredient_id IS 'Ингредиент';
COMMENT ON COLUMN ingredient_tenant_stock.qty IS 'Текущий остаток (точность до 0.001)';
COMMENT ON COLUMN ingredient_tenant_stock.min_qty IS 'Минимальный остаток для алерта';
COMMENT ON COLUMN ingredient_tenant_stock.updated_at IS 'Время последнего изменения остатка';

CREATE INDEX idx_tenant_stock_tenant ON ingredient_tenant_stock(tenant_id);
CREATE INDEX idx_tenant_stock_ingredient ON ingredient_tenant_stock(ingredient_id);
CREATE INDEX idx_tenant_stock_tenant_ingredient ON ingredient_tenant_stock(tenant_id, ingredient_id);
CREATE INDEX idx_tenant_stock_low ON ingredient_tenant_stock(tenant_id, qty) WHERE qty <= min_qty AND min_qty > 0;

-- ============================================================================
-- TABLE: stock_movements (движения склада — заголовок документа)
-- ============================================================================

CREATE TABLE IF NOT EXISTS stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    movement_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    reference_id UUID,
    note TEXT,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    confirmed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    confirmed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_movement_type CHECK (movement_type IN (
        'receipt', 'write_off', 'inventory', 'order_deduct', 'return'
    )),
    CONSTRAINT chk_movement_status CHECK (status IN ('draft', 'confirmed', 'cancelled'))
);

COMMENT ON TABLE stock_movements IS 'Движения склада — заголовки документов';
COMMENT ON COLUMN stock_movements.id IS 'Уникальный идентификатор движения';
COMMENT ON COLUMN stock_movements.tenant_id IS 'Тенант (точка продаж)';
COMMENT ON COLUMN stock_movements.movement_type IS 'Тип движения: receipt, write_off, inventory, order_deduct, return';
COMMENT ON COLUMN stock_movements.status IS 'Статус: draft, confirmed, cancelled';
COMMENT ON COLUMN stock_movements.reference_id IS 'Ссылка на связанный документ (order_id для order_deduct)';
COMMENT ON COLUMN stock_movements.note IS 'Комментарий к движению';
COMMENT ON COLUMN stock_movements.created_by IS 'Пользователь создавший документ';
COMMENT ON COLUMN stock_movements.confirmed_by IS 'Пользователь подтвердивший документ';
COMMENT ON COLUMN stock_movements.confirmed_at IS 'Время подтверждения';

CREATE INDEX idx_stock_movements_tenant ON stock_movements(tenant_id);
CREATE INDEX idx_stock_movements_type ON stock_movements(movement_type);
CREATE INDEX idx_stock_movements_status ON stock_movements(status);
CREATE INDEX idx_stock_movements_created_at ON stock_movements(created_at);
CREATE INDEX idx_stock_movements_reference ON stock_movements(reference_id);
CREATE INDEX idx_stock_movements_tenant_status ON stock_movements(tenant_id, status);

-- ============================================================================
-- TABLE: stock_movement_items (позиции документа движения)
-- ============================================================================

CREATE TABLE IF NOT EXISTS stock_movement_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    movement_id UUID NOT NULL REFERENCES stock_movements(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    qty_change DECIMAL(10,3) NOT NULL,
    qty_before DECIMAL(10,3),
    qty_after DECIMAL(10,3),
    unit_cost DECIMAL(10,2),
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_qty_change_nonzero CHECK (qty_change != 0)
);

COMMENT ON TABLE stock_movement_items IS 'Позиции документа движения склада';
COMMENT ON COLUMN stock_movement_items.id IS 'Уникальный идентификатор позиции';
COMMENT ON COLUMN stock_movement_items.movement_id IS 'Ссылка на движение';
COMMENT ON COLUMN stock_movement_items.ingredient_id IS 'Ингредиент';
COMMENT ON COLUMN stock_movement_items.qty_change IS 'Изменение количества (+ приход, - расход)';
COMMENT ON COLUMN stock_movement_items.qty_before IS 'Остаток ДО движения (снапшот)';
COMMENT ON COLUMN stock_movement_items.qty_after IS 'Остаток ПОСЛЕ движения (снапшот)';
COMMENT ON COLUMN stock_movement_items.unit_cost IS 'Себестоимость единицы (для receipt)';
COMMENT ON COLUMN stock_movement_items.note IS 'Комментарий к позиции';

CREATE INDEX idx_movement_items_movement ON stock_movement_items(movement_id);
CREATE INDEX idx_movement_items_ingredient ON stock_movement_items(ingredient_id);
CREATE INDEX idx_movement_items_movement_ingredient ON stock_movement_items(movement_id, ingredient_id);

-- ============================================================================
-- TABLE: product_recipes (ТТК — рецепты продуктов, создаёт УК)
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    qty_per_serving DECIMAL(10,3) NOT NULL,
    note TEXT,
    UNIQUE(product_id, ingredient_id),
    CONSTRAINT chk_recipe_qty CHECK (qty_per_serving > 0)
);

COMMENT ON TABLE product_recipes IS 'ТТК — рецепты продуктов (создаёт УК)';
COMMENT ON COLUMN product_recipes.id IS 'Уникальный идентификатор записи рецепта';
COMMENT ON COLUMN product_recipes.product_id IS 'Продукт';
COMMENT ON COLUMN product_recipes.ingredient_id IS 'Ингредиент';
COMMENT ON COLUMN product_recipes.qty_per_serving IS 'Расход ингредиента на 1 порцию';
COMMENT ON COLUMN product_recipes.note IS 'Комментарий (например "для базового размера")';

CREATE INDEX idx_product_recipes_product ON product_recipes(product_id);
CREATE INDEX idx_product_recipes_ingredient ON product_recipes(ingredient_id);
CREATE INDEX idx_product_recipes_product_ingredient ON product_recipes(product_id, ingredient_id);

-- ============================================================================
-- TABLE: modifier_option_recipes (влияние модификатора на расход ингредиентов)
-- ============================================================================

CREATE TABLE IF NOT EXISTS modifier_option_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    option_id UUID NOT NULL REFERENCES product_modifier_options(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    qty_change DECIMAL(10,3) NOT NULL,
    note TEXT,
    UNIQUE(option_id, ingredient_id)
);

COMMENT ON TABLE modifier_option_recipes IS 'Влияние модификатора на расход ингредиентов (создаёт УК)';
COMMENT ON COLUMN modifier_option_recipes.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN modifier_option_recipes.option_id IS 'Опция модификатора';
COMMENT ON COLUMN modifier_option_recipes.ingredient_id IS 'Ингредиент';
COMMENT ON COLUMN modifier_option_recipes.qty_change IS 'Изменение расхода (+ добавить, - убрать)';
COMMENT ON COLUMN modifier_option_recipes.note IS 'Комментарий';

CREATE INDEX idx_modifier_recipes_option ON modifier_option_recipes(option_id);
CREATE INDEX idx_modifier_recipes_ingredient ON modifier_option_recipes(ingredient_id);
CREATE INDEX idx_modifier_recipes_option_ingredient ON modifier_option_recipes(option_id, ingredient_id);

-- ============================================================================
-- ALTER TABLE: product_tenant_settings - добавляем low_stock_alert
-- ============================================================================

ALTER TABLE product_tenant_settings 
    ADD COLUMN IF NOT EXISTS low_stock_alert BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN product_tenant_settings.low_stock_alert IS 'TRUE если суммарный остаток ключевых ингредиентов < min_qty';

CREATE INDEX IF NOT EXISTS idx_tenant_settings_low_stock ON product_tenant_settings(tenant_id, low_stock_alert) 
    WHERE low_stock_alert = TRUE;

-- ============================================================================
-- TRIGGER: Автоматическое обновление updated_at
-- ============================================================================

CREATE TRIGGER trg_ingredients_updated_at
    BEFORE UPDATE ON ingredients
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_tenant_stock_updated_at
    BEFORE UPDATE ON ingredient_tenant_stock
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_stock_movements_updated_at
    BEFORE UPDATE ON stock_movements
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER: Подтверждение движения склада (обновление остатков)
-- ============================================================================

CREATE OR REPLACE FUNCTION trg_stock_movement_confirmed_handler()
RETURNS TRIGGER AS $$
DECLARE
    v_item RECORD;
    v_current_qty DECIMAL(10,3);
    v_new_qty DECIMAL(10,3);
BEGIN
    -- Срабатывает только при переходе в confirmed
    IF OLD.status != 'confirmed' AND NEW.status = 'confirmed' THEN
        -- Для каждой позиции движения обновляем остатки
        FOR v_item IN 
            SELECT * FROM stock_movement_items WHERE movement_id = NEW.id
        LOOP
            -- Получаем текущий остаток с блокировкой
            SELECT qty INTO v_current_qty
            FROM ingredient_tenant_stock
            WHERE tenant_id = NEW.tenant_id AND ingredient_id = v_item.ingredient_id
            FOR UPDATE;
            
            -- Если записи нет — создаём
            IF v_current_qty IS NULL THEN
                v_current_qty := 0;
                INSERT INTO ingredient_tenant_stock (tenant_id, ingredient_id, qty, min_qty)
                VALUES (NEW.tenant_id, v_item.ingredient_id, 0, 0);
            END IF;
            
            -- Вычисляем новый остаток
            v_new_qty := v_current_qty + v_item.qty_change;
            
            -- Обновляем остаток
            UPDATE ingredient_tenant_stock
            SET qty = v_new_qty,
                updated_at = NOW()
            WHERE tenant_id = NEW.tenant_id AND ingredient_id = v_item.ingredient_id;
            
            -- Обновляем снапшоты в позиции движения
            UPDATE stock_movement_items
            SET qty_before = v_current_qty,
                qty_after = v_new_qty
            WHERE id = v_item.id;
        END LOOP;
        
        -- Отдельный UPDATE для confirmed_at (AFTER триггер не может изменить NEW)
        UPDATE stock_movements 
        SET confirmed_at = NOW() 
        WHERE id = NEW.id AND confirmed_at IS NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_stock_movement_confirmed
    AFTER UPDATE ON stock_movements
    FOR EACH ROW
    EXECUTE FUNCTION trg_stock_movement_confirmed_handler();

-- ============================================================================
-- TRIGGER: Обновление стоп-листа при изменении остатков
-- ============================================================================

CREATE OR REPLACE FUNCTION trg_update_stoplist_handler()
RETURNS TRIGGER AS $$
DECLARE
    v_product RECORD;
    v_has_zero_ingredient BOOLEAN;
BEGIN
    -- Находим все продукты которые используют этот ингредиент
    FOR v_product IN 
        SELECT DISTINCT pr.product_id, pts.id AS settings_id, pts.is_sold_out, pts.sold_out_reason
        FROM product_recipes pr
        JOIN product_tenant_settings pts ON pr.product_id = pts.product_id
        WHERE pts.tenant_id = NEW.tenant_id
          AND pr.ingredient_id = NEW.ingredient_id
    LOOP
        -- EXISTS подзапрос для проверки наличия ингредиента с qty=0
        SELECT EXISTS(
            SELECT 1
            FROM product_recipes pr2
            JOIN ingredient_tenant_stock its2 
                ON pr2.ingredient_id = its2.ingredient_id 
                AND its2.tenant_id = NEW.tenant_id
            WHERE pr2.product_id = v_product.product_id
              AND its2.qty = 0
        ) INTO v_has_zero_ingredient;
        
        -- Если есть ингредиент с qty=0 → ставим стоп
        IF v_has_zero_ingredient = TRUE THEN
            UPDATE product_tenant_settings
            SET is_sold_out = TRUE,
                sold_out_reason = 'stock_empty',
                updated_at = NOW()
            WHERE id = v_product.settings_id
              AND (sold_out_reason IS NULL OR sold_out_reason != 'manual');
        -- Если все ингредиенты > 0 и был автостоп → снимаем стоп
        ELSIF v_product.is_sold_out = TRUE AND v_product.sold_out_reason = 'stock_empty' THEN
            UPDATE product_tenant_settings
            SET is_sold_out = FALSE,
                sold_out_reason = NULL,
                updated_at = NOW()
            WHERE id = v_product.settings_id;
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_stoplist
    AFTER UPDATE OF qty ON ingredient_tenant_stock
    FOR EACH ROW
    EXECUTE FUNCTION trg_update_stoplist_handler();

-- ============================================================================
-- TRIGGER: Автосписание при создании заказа
-- ИСПРАВЛЕНИЕ: v_single_mod_qty для накопления дельт модификаторов
-- ============================================================================

CREATE OR REPLACE FUNCTION trg_order_deduct_handler()
RETURNS TRIGGER AS $$
DECLARE
    v_movement_id UUID;
    v_item RECORD;
    v_ingredient RECORD;
    v_base_qty DECIMAL(10,3);
    v_single_mod_qty DECIMAL(10,3);  -- временная переменная для одного модификатора
    v_modifier_qty DECIMAL(10,3);    -- накопитель всех модификаторов
    v_total_qty DECIMAL(10,3);
    v_option_id UUID;
    v_modifier_options JSONB;
    v_mod_key TEXT;
    v_mod_value TEXT;
BEGIN
    -- Срабатывает только при переходе в preparing
    IF OLD.status != 'preparing' AND NEW.status = 'preparing' THEN
        -- Создаём как draft сначала
        INSERT INTO stock_movements (
            tenant_id, movement_type, status, reference_id, 
            note, created_by
        ) VALUES (
            NEW.tenant_id, 'order_deduct', 'draft', NEW.id,
            'Автосписание при заказе ' || NEW.order_number, 
            NULL
        ) RETURNING id INTO v_movement_id;
        
        -- Для каждой позиции заказа
        FOR v_item IN 
            SELECT * FROM order_items WHERE order_id = NEW.id
        LOOP
            v_modifier_options := v_item.modifier_options;
            
            -- Для каждого ингредиента в рецепте продукта
            FOR v_ingredient IN 
                SELECT pr.ingredient_id, pr.qty_per_serving, pr.note
                FROM product_recipes pr
                WHERE pr.product_id = v_item.product_id
            LOOP
                -- Базовый расход × количество в заказе
                v_base_qty := v_ingredient.qty_per_serving * v_item.quantity;
                
                -- Сбрасываем накопитель модификаторов для этого ингредиента
                v_modifier_qty := 0;
                
                -- Учитываем модификаторы через option_id в JSONB
                IF v_modifier_options IS NOT NULL AND v_modifier_options != '{}'::JSONB THEN
                    FOR v_mod_key, v_mod_value IN 
                        SELECT key, value::text
                        FROM jsonb_each_text(v_modifier_options)
                    LOOP
                        BEGIN
                            -- Пытаемся распарсить значение как UUID (option_id)
                            v_option_id := v_mod_value::UUID;
                            
                            -- Получаем дельту от ЭТОГО модификатора во временную переменную
                            SELECT COALESCE(mor.qty_change, 0) * v_item.quantity
                            INTO v_single_mod_qty
                            FROM modifier_option_recipes mor
                            WHERE mor.option_id = v_option_id
                              AND mor.ingredient_id = v_ingredient.ingredient_id;
                            
                            -- ИСПРАВЛЕНИЕ: Накапливаем через += а не перезаписываем
                            v_modifier_qty := v_modifier_qty + COALESCE(v_single_mod_qty, 0);
                            
                        EXCEPTION WHEN INVALID_TEXT_REPRESENTATION THEN
                            -- Если значение не UUID — пропускаем (старый формат данных)
                            CONTINUE;
                        END;
                    END LOOP;
                END IF;
                
                -- Итоговый расход = базовый + ВСЕ модификаторы (накопленные)
                v_total_qty := v_base_qty + v_modifier_qty;
                
                -- Добавляем позицию в движение (только если есть расход)
                IF v_total_qty != 0 THEN
                    INSERT INTO stock_movement_items (
                        movement_id, ingredient_id, qty_change, note
                    ) VALUES (
                        v_movement_id, 
                        v_ingredient.ingredient_id, 
                        -v_total_qty,  -- отрицательное = расход
                        COALESCE(v_ingredient.note, 'Базовый расход')
                    );
                END IF;
            END LOOP;
        END LOOP;
        
        -- Теперь подтверждаем — это вызовет триггер обновления остатков
        UPDATE stock_movements 
        SET status = 'confirmed', 
            confirmed_at = NOW(),
            updated_at = NOW()
        WHERE id = v_movement_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_deduct
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION trg_order_deduct_handler();

-- ============================================================================
-- VIEW: v_ingredient_stock — остатки ингредиентов на точке
-- ============================================================================

CREATE OR REPLACE VIEW v_ingredient_stock AS
SELECT 
    its.tenant_id,
    its.ingredient_id,
    i.name AS ingredient_name,
    i.unit,
    i.category,
    its.qty,
    its.min_qty,
    (its.qty <= its.min_qty AND its.min_qty > 0) AS is_low_stock,
    (its.qty = 0) AS is_out_of_stock
FROM ingredient_tenant_stock its
JOIN ingredients i ON its.ingredient_id = i.id
ORDER BY is_out_of_stock DESC, is_low_stock DESC, i.name ASC;

COMMENT ON VIEW v_ingredient_stock IS 'Остатки ингредиентов на точке с флагами low/out of stock';

-- ============================================================================
-- VIEW: v_product_recipe_full — полный рецепт продукта с модификаторами
-- ============================================================================

CREATE OR REPLACE VIEW v_product_recipe_full AS
SELECT 
    p.id AS product_id,
    p.name AS product_name,
    pr.ingredient_id,
    i.name AS ingredient_name,
    i.unit,
    pr.qty_per_serving,
    pmg.name AS modifier_group_name,
    pmo.name AS modifier_option_name,
    mor.qty_change AS modifier_qty_change
FROM products p
JOIN product_recipes pr ON p.id = pr.product_id
JOIN ingredients i ON pr.ingredient_id = i.id
LEFT JOIN modifier_option_recipes mor 
    ON pr.ingredient_id = mor.ingredient_id
    AND EXISTS (
        SELECT 1 
        FROM product_modifier_options pmo2
        JOIN product_modifier_groups pmg2 ON pmo2.group_id = pmg2.id
        WHERE pmo2.id = mor.option_id
          AND pmg2.product_id = p.id
    )
LEFT JOIN product_modifier_options pmo ON mor.option_id = pmo.id
LEFT JOIN product_modifier_groups pmg ON pmo.group_id = pmg.id
ORDER BY p.sort_order, pr.ingredient_id, pmg.sort_order, pmo.sort_order;

COMMENT ON VIEW v_product_recipe_full IS 'Полный рецепт продукта с влиянием модификаторов';

-- ============================================================================
-- VIEW: v_stoplist_status — текущий стоп-лист точки с причиной
-- ============================================================================

CREATE OR REPLACE VIEW v_stoplist_status AS
SELECT 
    pts.tenant_id,
    pts.product_id,
    p.name AS product_name,
    pts.is_sold_out,
    pts.sold_out_reason,
    blocking_i.name AS blocking_ingredient_name,
    blocking_its.qty AS blocking_ingredient_qty
FROM product_tenant_settings pts
JOIN products p ON pts.product_id = p.id
LEFT JOIN LATERAL (
    SELECT pr2.ingredient_id
    FROM product_recipes pr2
    JOIN ingredient_tenant_stock its2 
        ON pr2.ingredient_id = its2.ingredient_id 
        AND its2.tenant_id = pts.tenant_id
    WHERE pr2.product_id = pts.product_id
      AND its2.qty = 0
    LIMIT 1
) blocking_pr ON TRUE
LEFT JOIN ingredients blocking_i ON blocking_pr.ingredient_id = blocking_i.id
LEFT JOIN ingredient_tenant_stock blocking_its 
    ON blocking_pr.ingredient_id = blocking_its.ingredient_id 
    AND blocking_its.tenant_id = pts.tenant_id
WHERE pts.is_sold_out = TRUE
ORDER BY pts.sold_out_reason, p.name;

COMMENT ON VIEW v_stoplist_status IS 'Текущий стоп-лист точки с блокирующим ингредиентом';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE ingredient_tenant_stock ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movement_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_ingredient_stock ON ingredient_tenant_stock
    FOR ALL
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager')
        )
    );

CREATE POLICY rls_tenant_stock_movements ON stock_movements
    FOR ALL
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager')
        )
    );

CREATE POLICY rls_tenant_stock_movement_items ON stock_movement_items
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM stock_movements sm
            WHERE sm.id = stock_movement_items.movement_id
            AND (
                sm.tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
                OR EXISTS (
                    SELECT 1 FROM user_roles ur
                    JOIN roles r ON ur.role_id = r.id
                    WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                    AND r.code IN ('ук_global_admin', 'ук_country_manager')
                )
            )
        )
    );

-- Глобальные таблицы — read-only для всех, запись только УК
ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE modifier_option_recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_ingredients_read ON ingredients
    FOR SELECT USING (TRUE);

CREATE POLICY rls_ingredients_write ON ingredients
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager')
        )
    );

CREATE POLICY rls_product_recipes_read ON product_recipes
    FOR SELECT USING (TRUE);

CREATE POLICY rls_product_recipes_write ON product_recipes
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager')
        )
    );

CREATE POLICY rls_modifier_recipes_read ON modifier_option_recipes
    FOR SELECT USING (TRUE);

CREATE POLICY rls_modifier_recipes_write ON modifier_option_recipes
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager')
        )
    );

-- ============================================================================
-- ФУНКЦИИ ПОМОЩНИКИ
-- ============================================================================

CREATE OR REPLACE FUNCTION create_stock_receipt(
    p_tenant_id UUID,
    p_items JSONB,
    p_created_by UUID DEFAULT NULL,
    p_note TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_movement_id UUID;
    v_item JSONB;
BEGIN
    INSERT INTO stock_movements (tenant_id, movement_type, status, note, created_by)
    VALUES (p_tenant_id, 'receipt', 'draft', p_note, p_created_by)
    RETURNING id INTO v_movement_id;
    
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO stock_movement_items (movement_id, ingredient_id, qty_change, unit_cost)
        VALUES (
            v_movement_id,
            (v_item->>'ingredient_id')::UUID,
            (v_item->>'qty')::DECIMAL(10,3),
            (v_item->>'unit_cost')::DECIMAL(10,2)
        );
    END LOOP;
    
    RETURN v_movement_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION confirm_stock_movement(
    p_movement_id UUID,
    p_confirmed_by UUID DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE stock_movements
    SET status = 'confirmed',
        confirmed_by = p_confirmed_by,
        updated_at = NOW()
    WHERE id = p_movement_id
      AND status = 'draft';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Движение не найдено или уже подтверждено/отменено';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION perform_inventory(
    p_tenant_id UUID,
    p_items JSONB,
    p_created_by UUID DEFAULT NULL,
    p_note TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_movement_id UUID;
    v_item JSONB;
    v_current_qty DECIMAL(10,3);
    v_qty_diff DECIMAL(10,3);
BEGIN
    INSERT INTO stock_movements (tenant_id, movement_type, status, note, created_by)
    VALUES (p_tenant_id, 'inventory', 'draft', p_note, p_created_by)
    RETURNING id INTO v_movement_id;
    
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        SELECT qty INTO v_current_qty
        FROM ingredient_tenant_stock
        WHERE tenant_id = p_tenant_id 
          AND ingredient_id = (v_item->>'ingredient_id')::UUID;
        
        v_current_qty := COALESCE(v_current_qty, 0);
        v_qty_diff := (v_item->>'actual_qty')::DECIMAL(10,3) - v_current_qty;
        
        IF v_qty_diff != 0 THEN
            INSERT INTO stock_movement_items (movement_id, ingredient_id, qty_change, note)
            VALUES (
                v_movement_id,
                (v_item->>'ingredient_id')::UUID,
                v_qty_diff,
                'Инвентаризация: было ' || v_current_qty || ', стало ' || (v_item->>'actual_qty')
            );
        END IF;
    END LOOP;
    
    RETURN v_movement_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION check_product_availability(
    p_tenant_id UUID,
    p_product_id UUID
)
RETURNS TABLE (
    is_available BOOLEAN,
    blocking_ingredient_id UUID,
    blocking_ingredient_name VARCHAR(255),
    blocking_ingredient_qty DECIMAL(10,3)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (COUNT(*) = 0) AS is_available,
        MAX(its.ingredient_id) AS blocking_ingredient_id,
        MAX(i.name) AS blocking_ingredient_name,
        MAX(its.qty) AS blocking_ingredient_qty
    FROM product_recipes pr
    JOIN ingredient_tenant_stock its 
        ON pr.ingredient_id = its.ingredient_id 
        AND its.tenant_id = p_tenant_id
    JOIN ingredients i ON its.ingredient_id = i.id
    WHERE pr.product_id = p_product_id
      AND its.qty = 0;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- SEED DATA: Первичное заполнение
-- ============================================================================

BEGIN;

SET LOCAL row_security = off;

INSERT INTO ingredients (name, unit, category, is_active, created_by) VALUES
('Кофе эспрессо', 'g', 'coffee', TRUE, NULL),
('Молоко коровье', 'ml', 'milk', TRUE, NULL),
('Молоко овсяное', 'ml', 'milk', TRUE, NULL),
('Молоко кокосовое', 'ml', 'milk', TRUE, NULL),
('Стакан 400мл', 'pcs', 'cup', TRUE, NULL),
('Крышка', 'pcs', 'packaging', TRUE, NULL),
('Сироп ваниль', 'ml', 'syrup', TRUE, NULL)
ON CONFLICT DO NOTHING;

INSERT INTO ingredient_tenant_stock (tenant_id, ingredient_id, qty, min_qty)
SELECT 
    '00000000-0000-0000-0000-000000000001',
    i.id,
    CASE i.name
        WHEN 'Кофе эспрессо' THEN 500
        WHEN 'Молоко коровье' THEN 3000
        WHEN 'Молоко овсяное' THEN 1000
        WHEN 'Молоко кокосовое' THEN 500
        WHEN 'Стакан 400мл' THEN 100
        WHEN 'Крышка' THEN 100
        WHEN 'Сироп ваниль' THEN 200
        ELSE 0
    END,
    CASE i.name
        WHEN 'Кофе эспрессо' THEN 100
        WHEN 'Молоко коровье' THEN 500
        WHEN 'Молоко овсяное' THEN 200
        WHEN 'Молоко кокосовое' THEN 100
        WHEN 'Стакан 400мл' THEN 20
        WHEN 'Крышка' THEN 20
        WHEN 'Сироп ваниль' THEN 50
        ELSE 0
    END
FROM ingredients i
ON CONFLICT (tenant_id, ingredient_id) DO UPDATE SET
    qty = EXCLUDED.qty,
    min_qty = EXCLUDED.min_qty,
    updated_at = NOW();

INSERT INTO product_recipes (product_id, ingredient_id, qty_per_serving)
SELECT 
    '30000000-0000-0000-0000-000000000001',
    i.id,
    CASE i.name
        WHEN 'Кофе эспрессо' THEN 18
        WHEN 'Молоко коровье' THEN 150
        WHEN 'Стакан 400мл' THEN 1
        WHEN 'Крышка' THEN 1
        ELSE 0
    END
FROM ingredients i
WHERE i.name IN ('Кофе эспрессо', 'Молоко коровье', 'Стакан 400мл', 'Крышка')
ON CONFLICT (product_id, ingredient_id) DO UPDATE SET
    qty_per_serving = EXCLUDED.qty_per_serving;

INSERT INTO modifier_option_recipes (option_id, ingredient_id, qty_change)
SELECT 
    '50000000-0000-0000-0000-000000000002',
    i.id,
    CASE i.name
        WHEN 'Молоко коровье' THEN -150
        WHEN 'Молоко овсяное' THEN 150
        ELSE 0
    END
FROM ingredients i
WHERE i.name IN ('Молоко коровье', 'Молоко овсяное')
ON CONFLICT (option_id, ingredient_id) DO UPDATE SET
    qty_change = EXCLUDED.qty_change;

INSERT INTO modifier_option_recipes (option_id, ingredient_id, qty_change)
SELECT 
    '50000000-0000-0000-0000-000000000003',
    i.id,
    CASE i.name
        WHEN 'Молоко коровье' THEN -150
        WHEN 'Молоко кокосовое' THEN 150
        ELSE 0
    END
FROM ingredients i
WHERE i.name IN ('Молоко коровье', 'Молоко кокосовое')
ON CONFLICT (option_id, ingredient_id) DO UPDATE SET
    qty_change = EXCLUDED.qty_change;

COMMIT;

-- ============================================================================
-- КОНЕЦ МИГРАЦИЙ ЭТАПА 5
-- ============================================================================

/*
================================================================================
ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ

1. КАК ДОБАВИТЬ ПРИХОД ПФ НА ТОЧКУ
   SELECT create_stock_receipt('tenant-uuid', '[{"ingredient_id": "...", "qty": 500}]'::JSONB, 'user-uuid');
   SELECT confirm_stock_movement('movement-uuid', 'user-uuid');

2. КАК ПРОВЕСТИ ИНВЕНТАРИЗАЦИЮ
   SELECT perform_inventory('tenant-uuid', '[{"ingredient_id": "...", "actual_qty": 450}]'::JSONB, 'user-uuid');
   SELECT confirm_stock_movement('movement-uuid', 'user-uuid');

3. КАК РАБОТАЕТ АВТОСПИСАНИЕ ПРИ ЗАКАЗЕ
   - При переходе в 'preparing' создаётся stock_movement (draft)
   - Добавляются позиции с учётом модификаторов (через option_id UUID)
   - UPDATE на confirmed вызывает триггер обновления остатков
   - Триггер стоп-листа проверяет и обновляет product_tenant_settings

4. КАК ПРОВЕРИТЬ БЛОКИРУЮЩИЙ ИНГРЕДИЕНТ
   SELECT * FROM v_stoplist_status WHERE tenant_id = 'tenant-uuid';
   SELECT * FROM check_product_availability('tenant-uuid', 'product-uuid');

================================================================================
ИСПРАВЛЕНИЯ В ЭТОЙ ВЕРСИИ (5.3)

1. ✅ v_single_mod_qty для накопления модификаторов
   - v_single_mod_qty: получает дельту от ОДНОГО модификатора
   - v_modifier_qty: накапливает ВСЕ дельты через +=
   - Пример: молоко (-150мл) + сироп (+20мл) = -130мл (оба учтены)

2. ✅ Все предыдущие исправления сохранены:
   - (sold_out_reason IS NULL OR sold_out_reason != 'manual') — стоп-лист
   - draft → confirmed через UPDATE — триггер срабатывает
   - EXISTS вместо MAX(BOOLEAN) — проверка нулевых остатков
   - Отдельный UPDATE для confirmed_at — AFTER триггер
   - Поиск модификатора по UUID с EXCEPTION — надёжный парсинг

================================================================================
ТРЕБОВАНИЯ К order_items.modifier_options ФОРМАТУ
================================================================================

Для корректной работы списания модификаторов, modifier_options в order_items
должен содержать option_id UUID в значениях:

✅ Правильный формат (работает списание модификаторов):
{
  "milk_type": "50000000-0000-0000-0000-000000000002",
  "syrup": "50000000-0000-0000-0000-000000000020"
}

❌ Неправильный формат (списывается только базовый рецепт):
{
  "milk_type": "oat_milk",
  "syrup": "vanilla"
}

При создании заказа в этапе 1 необходимо сохранять option_id UUID,
а не человекочитаемые названия. Это обеспечит точное списание ингредиентов
при любых модификаторах.

================================================================================
*/
```
apps-fileview.texmex_20260501.02_p0
ядро 5 этап.txt
ядро 5 этап.txt. На экране.