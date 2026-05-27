
```sql
-- ============================================================================
-- SQL МИГРАЦИИ ДЛЯ СИСТЕМЫ КОФЕЕН (POSTGRESQL)
-- ЭТАП 6: ЛОКАЛЬНЫЙ МОДУЛЬ — КИОСК (KIOSK)
-- Версия 1.4 - Исправлена логика фильтрации menu_type в v_kiosk_menu
-- ============================================================================

-- ============================================================================
-- TABLE: kiosk_settings (настройки киоска на точке)
-- ============================================================================

CREATE TABLE IF NOT EXISTS kiosk_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    idle_timeout_seconds INTEGER NOT NULL DEFAULT 60,
    welcome_text TEXT DEFAULT 'Добро пожаловать! Выберите ваш заказ',
    show_calories BOOLEAN NOT NULL DEFAULT FALSE,
    allow_cash BOOLEAN NOT NULL DEFAULT TRUE,
    allow_card BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    background_image_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, device_id),
    CONSTRAINT chk_idle_timeout CHECK (idle_timeout_seconds > 0 AND idle_timeout_seconds <= 600),
    CONSTRAINT chk_payment_methods CHECK (allow_cash = TRUE OR allow_card = TRUE)
);

COMMENT ON TABLE kiosk_settings IS 'Настройки киоска самообслуживания на точке';
COMMENT ON COLUMN kiosk_settings.id IS 'Уникальный идентификатор настроек';
COMMENT ON COLUMN kiosk_settings.tenant_id IS 'Тенант (точка продаж)';
COMMENT ON COLUMN kiosk_settings.device_id IS 'Устройство киоска';
COMMENT ON COLUMN kiosk_settings.idle_timeout_seconds IS 'Таймаут бездействия в секундах (60-600)';
COMMENT ON COLUMN kiosk_settings.welcome_text IS 'Приветственный текст на экране';
COMMENT ON COLUMN kiosk_settings.show_calories IS 'Показывать калорийность продуктов';
COMMENT ON COLUMN kiosk_settings.allow_cash IS 'Разрешена ли оплата наличными';
COMMENT ON COLUMN kiosk_settings.allow_card IS 'Разрешена ли оплата картой';
COMMENT ON COLUMN kiosk_settings.is_active IS 'Активен ли киоск';
COMMENT ON COLUMN kiosk_settings.background_image_url IS 'URL фонового изображения';

CREATE INDEX idx_kiosk_settings_tenant ON kiosk_settings(tenant_id);
CREATE INDEX idx_kiosk_settings_device ON kiosk_settings(device_id);
CREATE INDEX idx_kiosk_settings_active ON kiosk_settings(tenant_id, is_active) WHERE is_active = TRUE;

CREATE TRIGGER trg_kiosk_settings_updated_at
    BEFORE UPDATE ON kiosk_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TABLE: kiosk_carts (временная корзина клиента)
-- ============================================================================

CREATE TABLE IF NOT EXISTS kiosk_carts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_token UUID NOT NULL UNIQUE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    items JSONB NOT NULL DEFAULT '[]'::JSONB,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() + INTERVAL '30 minutes'),
    CONSTRAINT chk_cart_items CHECK (jsonb_array_length(items) >= 0),
    CONSTRAINT chk_cart_total CHECK (total_amount >= 0)
);

COMMENT ON TABLE kiosk_carts IS 'Временная корзина клиента до оформления заказа';
COMMENT ON COLUMN kiosk_carts.id IS 'Уникальный идентификатор корзины';
COMMENT ON COLUMN kiosk_carts.session_token IS 'Анонимный токен сессии клиента';
COMMENT ON COLUMN kiosk_carts.tenant_id IS 'Тенант (точка продаж)';
COMMENT ON COLUMN kiosk_carts.device_id IS 'Устройство киоска';
COMMENT ON COLUMN kiosk_carts.items IS 'Позиции корзины: [{"product_id": "uuid", "quantity": 2, "modifier_options": {...}, "price": 350.00}]';
COMMENT ON COLUMN kiosk_carts.total_amount IS 'Общая сумма корзины';
COMMENT ON COLUMN kiosk_carts.expires_at IS 'Время истечения срока корзины (TTL)';

CREATE INDEX idx_kiosk_carts_session_token ON kiosk_carts(session_token);
CREATE INDEX idx_kiosk_carts_tenant ON kiosk_carts(tenant_id);
CREATE INDEX idx_kiosk_carts_device ON kiosk_carts(device_id);
CREATE INDEX idx_kiosk_carts_expires_at ON kiosk_carts(expires_at);
CREATE INDEX idx_kiosk_carts_active ON kiosk_carts(tenant_id, expires_at) WHERE expires_at > NOW();

CREATE TRIGGER trg_kiosk_carts_updated_at
    BEFORE UPDATE ON kiosk_carts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TABLE: kiosk_sessions (сессия взаимодействия клиента с киоском)
-- ============================================================================

CREATE TABLE IF NOT EXISTS kiosk_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    session_token UUID NOT NULL UNIQUE,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    last_activity_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    orders_created INTEGER NOT NULL DEFAULT 0,
    end_reason VARCHAR(50),
    meta JSONB,
    CONSTRAINT chk_end_reason CHECK (end_reason IS NULL OR end_reason IN (
        'timeout', 'order_completed', 'manual_reset', 'device_offline'
    ))
);

COMMENT ON TABLE kiosk_sessions IS 'Сессия взаимодействия клиента с киоском';
COMMENT ON COLUMN kiosk_sessions.id IS 'Уникальный идентификатор сессии';
COMMENT ON COLUMN kiosk_sessions.device_id IS 'Устройство киоска';
COMMENT ON COLUMN kiosk_sessions.tenant_id IS 'Тенант (точка продаж)';
COMMENT ON COLUMN kiosk_sessions.session_token IS 'Токен сессии (совпадает с kiosk_carts.session_token)';
COMMENT ON COLUMN kiosk_sessions.started_at IS 'Время начала сессии';
COMMENT ON COLUMN kiosk_sessions.ended_at IS 'Время завершения (NULL = активна)';
COMMENT ON COLUMN kiosk_sessions.last_activity_at IS 'Последняя активность клиента';
COMMENT ON COLUMN kiosk_sessions.orders_created IS 'Количество заказов созданных за сессию';
COMMENT ON COLUMN kiosk_sessions.end_reason IS 'Причина завершения: timeout, order_completed, manual_reset, device_offline';
COMMENT ON COLUMN kiosk_sessions.meta IS 'Дополнительные данные сессии';

CREATE INDEX idx_kiosk_sessions_device ON kiosk_sessions(device_id);
CREATE INDEX idx_kiosk_sessions_tenant ON kiosk_sessions(tenant_id);
CREATE INDEX idx_kiosk_sessions_token ON kiosk_sessions(session_token);
CREATE INDEX idx_kiosk_sessions_active ON kiosk_sessions(device_id, last_activity_at) WHERE ended_at IS NULL;
CREATE INDEX idx_kiosk_sessions_ended_at ON kiosk_sessions(ended_at) WHERE ended_at IS NULL;

-- Partial unique index: одна активная сессия на устройство
CREATE UNIQUE INDEX idx_kiosk_sessions_one_active_per_device 
    ON kiosk_sessions(device_id) 
    WHERE ended_at IS NULL;

-- ============================================================================
-- FUNCTION: start_kiosk_session
-- ============================================================================

CREATE OR REPLACE FUNCTION start_kiosk_session(
    p_device_id UUID,
    p_tenant_id UUID
)
RETURNS TABLE (
    session_token UUID,
    session_id UUID
) AS $$
DECLARE
    v_session_token UUID;
    v_session_id UUID;
    v_timeout_seconds INTEGER;
BEGIN
    -- Завершаем предыдущую активную сессию на этом устройстве
    UPDATE kiosk_sessions
    SET ended_at = NOW(),
        end_reason = 'manual_reset'
    WHERE device_id = p_device_id
      AND ended_at IS NULL;
    
    -- Получаем таймаут из настроек
    SELECT COALESCE(idle_timeout_seconds, 60) INTO v_timeout_seconds
    FROM kiosk_settings
    WHERE device_id = p_device_id AND tenant_id = p_tenant_id;
    
    -- Генерируем токен сессии
    v_session_token := gen_random_uuid();
    
    -- Создаём новую сессию
    INSERT INTO kiosk_sessions (device_id, tenant_id, session_token, meta)
    VALUES (p_device_id, p_tenant_id, v_session_token, '{"source": "kiosk"}')
    RETURNING id INTO v_session_id;
    
    -- Создаём корзину
    INSERT INTO kiosk_carts (session_token, tenant_id, device_id, expires_at)
    VALUES (
        v_session_token, 
        p_tenant_id, 
        p_device_id,
        NOW() + (v_timeout_seconds || ' seconds')::INTERVAL
    );
    
    RETURN QUERY SELECT v_session_token, v_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: update_kiosk_cart
-- ============================================================================

CREATE OR REPLACE FUNCTION update_kiosk_cart(
    p_session_token UUID,
    p_tenant_id UUID,
    p_items JSONB,
    p_total_amount DECIMAL(10,2)
)
RETURNS VOID AS $$
DECLARE
    v_timeout_seconds INTEGER;
BEGIN
    -- Проверяем что сессия существует и не истекла
    PERFORM 1 FROM kiosk_carts
    WHERE session_token = p_session_token
      AND tenant_id = p_tenant_id
      AND expires_at > NOW()
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Сессия не найдена или истекла';
    END IF;
    
    -- Получаем таймаут для продления
    SELECT ks.idle_timeout_seconds INTO v_timeout_seconds
    FROM kiosk_carts kc
    JOIN kiosk_settings ks ON kc.device_id = ks.device_id
    WHERE kc.session_token = p_session_token;
    
    v_timeout_seconds := COALESCE(v_timeout_seconds, 60);
    
    -- Обновляем корзину
    UPDATE kiosk_carts
    SET items = p_items,
        total_amount = p_total_amount,
        updated_at = NOW(),
        expires_at = NOW() + (v_timeout_seconds || ' seconds')::INTERVAL
    WHERE session_token = p_session_token;
    
    -- Обновляем активность сессии
    UPDATE kiosk_sessions
    SET last_activity_at = NOW()
    WHERE session_token = p_session_token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: create_order_from_kiosk
-- ============================================================================

CREATE OR REPLACE FUNCTION create_order_from_kiosk(
    p_session_token UUID,
    p_tenant_id UUID,
    p_payment_method VARCHAR(50)
)
RETURNS TABLE (
    order_id UUID,
    order_number VARCHAR(20),
    payment_id UUID
) AS $$
DECLARE
    v_cart RECORD;
    v_order_id UUID;
    v_order_number VARCHAR(20);
    v_payment_id UUID;
    v_item JSONB;
    v_product_enabled BOOLEAN;
    v_product_sold_out BOOLEAN;
BEGIN
    -- Блокируем корзину для защиты от двойного создания заказа
    SELECT * INTO v_cart
    FROM kiosk_carts
    WHERE session_token = p_session_token
      AND tenant_id = p_tenant_id
      AND expires_at > NOW()
      AND jsonb_array_length(items) > 0
    FOR UPDATE;
    
    -- Проверка: IF NOT FOUND вместо IF v_cart IS NULL
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Корзина пуста или сессия истекла';
    END IF;
    
    -- Валидируем каждую позицию корзины
    FOR v_item IN SELECT * FROM jsonb_array_elements(v_cart.items)
    LOOP
        -- Проверяем что продукт включён и не в стоп-листе
        SELECT is_enabled, is_sold_out INTO v_product_enabled, v_product_sold_out
        FROM product_tenant_settings
        WHERE tenant_id = p_tenant_id
          AND product_id = (v_item->>'product_id')::UUID;
        
        -- Проверка: NOT FOUND OR NOT v_product_enabled
        IF NOT FOUND OR NOT v_product_enabled THEN
            RAISE EXCEPTION 'Продукт % недоступен', v_item->>'product_id';
        END IF;
        
        IF v_product_sold_out THEN
            RAISE EXCEPTION 'Продукт % раскуплен', v_item->>'product_id';
        END IF;
    END LOOP;
    
    -- Создаём заказ БЕЗ order_number и order_sequence
    -- Триггер trg_orders_set_number заполнит их автоматически
    INSERT INTO orders (
        tenant_id, source, status,
        total_amount, discount_amount, final_amount, created_at
    ) VALUES (
        p_tenant_id, 'kiosk', 'new',
        v_cart.total_amount, 0, v_cart.total_amount, NOW()
    )
    RETURNING id, order_number INTO v_order_id, v_order_number;
    
    -- Создаём позиции заказа
    FOR v_item IN SELECT * FROM jsonb_array_elements(v_cart.items)
    LOOP
        INSERT INTO order_items (
            order_id, product_id, quantity, modifier_options,
            unit_price, total_price
        ) VALUES (
            v_order_id,
            (v_item->>'product_id')::UUID,
            (v_item->>'quantity')::INTEGER,
            v_item->'modifier_options',
            (v_item->>'price')::DECIMAL(10,2),
            ((v_item->>'price')::DECIMAL(10,2) * (v_item->>'quantity')::INTEGER)
        );
    END LOOP;
    
    -- Создаём платёж
    INSERT INTO payments (
        tenant_id, order_id, amount, payment_method, status, created_at
    ) VALUES (
        p_tenant_id, v_order_id, v_cart.total_amount, p_payment_method,
        'pending', NOW()
    )
    RETURNING id INTO v_payment_id;
    
    -- Обновляем счётчик заказов в сессии
    UPDATE kiosk_sessions
    SET orders_created = orders_created + 1,
        last_activity_at = NOW()
    WHERE session_token = p_session_token;
    
    -- Очищаем корзину (помечаем как использованную)
    UPDATE kiosk_carts
    SET items = '[]'::JSONB,
        total_amount = 0,
        updated_at = NOW()
    WHERE session_token = p_session_token;
    
    RETURN QUERY SELECT v_order_id, v_order_number, v_payment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: reset_kiosk_session
-- ============================================================================

CREATE OR REPLACE FUNCTION reset_kiosk_session(
    p_device_id UUID,
    p_end_reason VARCHAR(50)
)
RETURNS VOID AS $$
BEGIN
    -- Завершаем активную сессию
    UPDATE kiosk_sessions
    SET ended_at = NOW(),
        end_reason = p_end_reason
    WHERE device_id = p_device_id
      AND ended_at IS NULL;
    
    -- Удаляем корзины этого устройства
    DELETE FROM kiosk_carts
    WHERE device_id = p_device_id
      AND session_token IN (
          SELECT session_token FROM kiosk_sessions
          WHERE device_id = p_device_id AND ended_at IS NOT NULL
      );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: cleanup_expired_kiosk_sessions
-- ============================================================================

CREATE OR REPLACE FUNCTION cleanup_expired_kiosk_sessions()
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Завершаем истёкшие сессии
    UPDATE kiosk_sessions
    SET ended_at = NOW(),
        end_reason = 'timeout'
    WHERE ended_at IS NULL
      AND last_activity_at < NOW() - INTERVAL '10 minutes';
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    
    -- Удаляем истёкшие корзины
    DELETE FROM kiosk_carts
    WHERE expires_at < NOW();
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- VIEW: v_kiosk_menu — меню для отображения на киоске
-- ИСПРАВЛЕНИЕ: EXISTS подзапросы вместо LEFT JOIN для фильтрации menu_type
-- ============================================================================

CREATE OR REPLACE VIEW v_kiosk_menu AS
SELECT 
    pts.tenant_id,
    p.id AS product_id,
    p.name AS product_name,
    p.slug AS product_slug,
    c.id AS category_id,
    c.name AS category_name,
    c.sort_order AS category_sort_order,
    pts.price,
    pts.is_sold_out,
    p.sort_order AS product_sort_order,
    pmg.id AS modifier_group_id,
    pmg.name AS modifier_group_name,
    pmg.is_required,
    pmg.sort_order AS group_sort_order,
    pmo.id AS modifier_option_id,
    pmo.name AS modifier_option_name,
    pmo.price_delta,
    pmo.sort_order AS option_sort_order,
    COALESCE(mots.price_delta_override, pmo.price_delta) AS final_price_delta
FROM products p
JOIN categories c ON p.category_id = c.id
JOIN product_tenant_settings pts ON p.id = pts.product_id
LEFT JOIN product_modifier_groups pmg ON p.id = pmg.product_id
LEFT JOIN product_modifier_options pmo ON pmg.id = pmo.group_id
LEFT JOIN modifier_option_tenant_settings mots 
    ON pmo.id = mots.option_id AND mots.tenant_id = pts.tenant_id
WHERE pts.is_enabled = TRUE
  AND pts.is_sold_out = FALSE
  AND pts.price IS NOT NULL
  AND (
    -- Нет записей о видимости вообще → показываем везде
    NOT EXISTS (
        SELECT 1 FROM product_menu_visibility pmv_check
        WHERE pmv_check.product_id = p.id
    )
    OR
    -- Явно включён в kiosk или main
    EXISTS (
        SELECT 1 FROM product_menu_visibility pmv2
        JOIN menu_types mt2 ON pmv2.menu_type_id = mt2.id
        WHERE pmv2.product_id = p.id
          AND mt2.code IN ('kiosk', 'main')
          AND pmv2.is_visible = TRUE
    )
  )
ORDER BY c.sort_order, p.sort_order, pmg.sort_order, pmo.sort_order;

COMMENT ON VIEW v_kiosk_menu IS 'Меню для отображения на киоске (только доступные продукты с модификаторами)';

-- ============================================================================
-- VIEW: v_kiosk_active_sessions — активные сессии киосков
-- ============================================================================

CREATE OR REPLACE VIEW v_kiosk_active_sessions AS
SELECT 
    ks.id AS session_id,
    ks.device_id,
    d.name AS device_name,
    ks.tenant_id,
    t.name AS tenant_name,
    ks.session_token,
    ks.started_at,
    ks.last_activity_at,
    ks.orders_created,
    EXTRACT(EPOCH FROM (NOW() - ks.last_activity_at))::INTEGER AS idle_seconds,
    kc.total_amount AS cart_total,
    jsonb_array_length(kc.items) AS cart_items_count
FROM kiosk_sessions ks
JOIN devices d ON ks.device_id = d.id
JOIN tenants t ON ks.tenant_id = t.id
LEFT JOIN kiosk_carts kc ON ks.session_token = kc.session_token
WHERE ks.ended_at IS NULL
ORDER BY ks.last_activity_at DESC;

COMMENT ON VIEW v_kiosk_active_sessions IS 'Активные сессии киосков с информацией о корзине';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE kiosk_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE kiosk_carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE kiosk_sessions ENABLE ROW LEVEL SECURITY;

-- kiosk_settings: read — все авторизованные устройства тенанта, write — office_manager и выше
CREATE POLICY rls_kiosk_settings_read ON kiosk_settings
    FOR SELECT
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager')
        )
    );

CREATE POLICY rls_kiosk_settings_write ON kiosk_settings
    FOR ALL
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        AND EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('office_manager', 'ук_global_admin', 'ук_country_manager')
        )
    );

-- kiosk_carts: доступ только по session_token или office_manager/УК
CREATE POLICY rls_kiosk_carts_session ON kiosk_carts
    FOR SELECT
    USING (
        session_token = NULLIF(current_setting('app.current_session_token', TRUE), '')::UUID
        OR tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('office_manager', 'ук_global_admin', 'ук_country_manager')
        )
    );

CREATE POLICY rls_kiosk_carts_write ON kiosk_carts
    FOR ALL
    USING (
        session_token = NULLIF(current_setting('app.current_session_token', TRUE), '')::UUID
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('office_manager', 'ук_global_admin', 'ук_country_manager')
        )
    );

-- kiosk_sessions: read — office_manager и выше своего тенанта + УК
CREATE POLICY rls_kiosk_sessions_read ON kiosk_sessions
    FOR SELECT
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        AND EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('office_manager', 'shift_manager', 'ук_global_admin', 'ук_country_manager')
        )
    );

CREATE POLICY rls_kiosk_sessions_write ON kiosk_sessions
    FOR ALL
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        AND EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('office_manager', 'ук_global_admin', 'ук_country_manager')
        )
    );

-- ============================================================================
-- SEED DATA: Первичное заполнение
-- ============================================================================

BEGIN;

SET LOCAL row_security = off;

-- 1. Добавляем menu_type 'kiosk' если его нет
INSERT INTO menu_types (code, name)
VALUES ('kiosk', 'Киоск самообслуживания')
ON CONFLICT (code) DO NOTHING;

-- 2. Добавляем настройки киоска для тестового тенанта
-- Предполагаем что device с name='kiosk_1' уже существует
INSERT INTO kiosk_settings (tenant_id, device_id, idle_timeout_seconds, welcome_text, show_calories, allow_cash, allow_card, is_active)
SELECT 
    '00000000-0000-0000-0000-000000000001',
    d.id,
    60,
    'Добро пожаловать! Выберите ваш заказ',
    FALSE,
    TRUE,
    TRUE,
    TRUE
FROM devices d
WHERE d.tenant_id = '00000000-0000-0000-0000-000000000001'
  AND d.device_type = 'kiosk'
  AND d.name = 'kiosk_1'
ON CONFLICT (tenant_id, device_id) DO UPDATE SET
    idle_timeout_seconds = EXCLUDED.idle_timeout_seconds,
    welcome_text = EXCLUDED.welcome_text,
    show_calories = EXCLUDED.show_calories,
    allow_cash = EXCLUDED.allow_cash,
    allow_card = EXCLUDED.allow_card,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

COMMIT;

-- ============================================================================
-- КОНЕЦ МИГРАЦИЙ ЭТАПА 6
-- ============================================================================

/*
================================================================================
ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ

1. КАК НАЧАТЬ СЕССИЮ КИОСКА

   SELECT * FROM start_kiosk_session(
       'device-uuid-here',
       'tenant-uuid-here'
   );
   
   -- Возвращает: session_token, session_id
   -- Сохраните session_token для последующих запросов

2. КАК ОБНОВИТЬ КОРЗИНУ

   SELECT update_kiosk_cart(
       'session-token-from-step-1',
       'tenant-uuid-here',
       '[
         {
           "product_id": "product-uuid",
           "quantity": 2,
           "modifier_options": {"milk_type": "option-uuid"},
           "price": 350.00
         }
       ]'::JSONB,
       700.00  -- total_amount
   );

3. КАК СОЗДАТЬ ЗАКАЗ ИЗ КОРЗИНЫ

   SELECT * FROM create_order_from_kiosk(
       'session-token-here',
       'tenant-uuid-here',
       'card'  -- или 'cash'
   );
   
   -- Возвращает: order_id, order_number, payment_id
   -- order_number генерируется автоматически триггером
   -- После этого корзина очищается

4. КАК СБРОСИТЬ СЕССИЮ (например при таймауте)

   SELECT reset_kiosk_session(
       'device-uuid-here',
       'timeout'  -- или 'manual_reset', 'device_offline'
   );

5. КАК ЗАПУСТИТЬ ОЧИСТКУ ИСТЁКШИХ СЕССИЙ

   -- Рекомендуется запускать по cron каждые 5 минут
   SELECT cleanup_expired_kiosk_sessions();

6. КАК ПОЛУЧИТЬ МЕНЮ ДЛЯ КИОСКА

   SELECT * FROM v_kiosk_menu
   WHERE tenant_id = 'tenant-uuid-here';

7. КАК ПОСМОТРЕТЬ АКТИВНЫЕ СЕССИИ

   SELECT * FROM v_kiosk_active_sessions
   WHERE tenant_id = 'tenant-uuid-here';

================================================================================
СОЗДАННЫЕ ОБЪЕКТЫ

ТАБЛИЦЫ:
- kiosk_settings (настройки киоска на точке)
- kiosk_carts (временная корзина клиента)
- kiosk_sessions (сессия взаимодействия с киоском)

ФУНКЦИИ:
- start_kiosk_session(p_device_id, p_tenant_id) — начать сессию
- update_kiosk_cart(p_session_token, p_tenant_id, p_items, p_total_amount) — обновить корзину
- create_order_from_kiosk(p_session_token, p_tenant_id, p_payment_method) — создать заказ
- reset_kiosk_session(p_device_id, p_end_reason) — сбросить сессию
- cleanup_expired_kiosk_sessions() — очистка истёкших сессий (cron)

VIEW:
- v_kiosk_menu — меню для отображения на киоске (с tenant_id)
- v_kiosk_active_sessions — активные сессии киосков

RLS ПОЛИТИКИ:
- kiosk_settings: read — устройства тенанта, write — office_manager+
- kiosk_carts: доступ по session_token или office_manager+
- kiosk_sessions: read — office_manager/shift_manager+, write — office_manager+

================================================================================
ИСПРАВЛЕНИЯ В ЭТОЙ ВЕРСИИ (1.4)

1. ✅ v_kiosk_menu: EXISTS подзапросы вместо LEFT JOIN для menu_type
   - Проблема: продукт для delivery (is_visible=TRUE) попадал в киоск
   - Причина: pmv.id IS NOT NULL, но mt = NULL (delivery не в JOIN условии)
   - WHERE pmv.is_visible = TRUE пропускал продукт
   - Решение: два EXISTS подзапроса
     a) NOT EXISTS product_menu_visibility → показываем везде
     b) EXISTS product_menu_visibility для kiosk/main с is_visible=TRUE
   - Теперь продукты для delivery не утекают в киоск-меню

================================================================================
АРХИТЕКТУРНЫЕ ЗАМЕЧАНИЯ

1. ✅ session_token — анонимный UUID, не связан с users.id
   - Клиент не авторизуется в киоске
   - После заказа customer_id сохраняется в облаке УК

2. ✅ FOR UPDATE при чтении корзины в create_order_from_kiosk
   - Защита от race condition при параллельных запросах
   - Двойное создание заказа невозможно

3. ✅ modifier_options сохраняются как {"group_key": "option_uuid"}
   - Соответствует формату order_items.modifier_options
   - UUID формат обеспечивает точное списание ингредиентов

4. ✅ Partial unique index на активную сессию
   - Только одна активная сессия на устройство
   - Предыдущая сессия завершается при start_kiosk_session

5. ✅ expires_at для корзины + last_activity_at для сессии
   - Двухуровневый контроль времени жизни
   - cleanup_expired_kiosk_sessions() для периодической очистки

6. ⚠️ payment создаётся со статусом 'pending'
   - Интеграция с платёжным провайдером — отдельный шаг
   - После успешной оплаты обновить payment.status и orders.status

7. ✅ v_kiosk_menu с EXISTS логикой
   - Продукты без product_menu_visibility → видны везде
   - Продукты с product_menu_visibility → только в указанных menu_type
   - Delivery продукты не попадают в киоск

8. ✅ DECIMAL(10,2) для цен в корзине
   - Соответствует orders.total_amount и order_items.price
   - DECIMAL(10,3) используется только для qty в рецептах

9. ✅ IF NOT FOUND проверки в create_order_from_kiosk
   - Корзина: IF NOT FOUND после SELECT INTO
   - Продукт: IF NOT FOUND OR NOT v_product_enabled
   - Корректная обработка отсутствующих записей в PL/pgSQL

================================================================================
*/
```
apps-fileview.texmex_20260501.02_p0
ядро 6 этап.txt
ядро 6 этап.txt. На экране.