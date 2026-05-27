
```sql
-- ============================================================================
-- SQL МИГРАЦИИ ДЛЯ СИСТЕМЫ КОФЕЕН (POSTGRESQL)
-- ЭТАП 10: УМНАЯ ВЫДАЧА (SMART PICKUP)
-- Версия 1.1 - Исправлены ADD CONSTRAINT и RLS политики
-- ============================================================================

-- ============================================================================
-- ЧАСТЬ A: ТАБЛИЦА pickup_display_settings
-- ============================================================================

CREATE TABLE IF NOT EXISTS pickup_display_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    display_mode VARCHAR(50) NOT NULL DEFAULT 'number',
    show_order_items BOOLEAN NOT NULL DEFAULT FALSE,
    items_visible_count INTEGER NOT NULL DEFAULT 10,
    auto_complete_seconds INTEGER,
    sound_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    welcome_message TEXT DEFAULT 'Ваш заказ готов!',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, device_id),
    CONSTRAINT chk_display_mode CHECK (display_mode IN ('number', 'name', 'both')),
    CONSTRAINT chk_items_visible_count CHECK (items_visible_count BETWEEN 1 AND 20),
    CONSTRAINT chk_auto_complete_seconds CHECK (auto_complete_seconds IS NULL OR auto_complete_seconds > 0)
);

COMMENT ON TABLE pickup_display_settings IS 'Настройки экрана выдачи на точке';
COMMENT ON COLUMN pickup_display_settings.id IS 'Уникальный идентификатор настроек';
COMMENT ON COLUMN pickup_display_settings.tenant_id IS 'Тенант (точка продаж)';
COMMENT ON COLUMN pickup_display_settings.device_id IS 'Устройство экрана выдачи';
COMMENT ON COLUMN pickup_display_settings.display_mode IS 'Режим отображения: number, name, both';
COMMENT ON COLUMN pickup_display_settings.show_order_items IS 'Показывать состав заказа на экране';
COMMENT ON COLUMN pickup_display_settings.items_visible_count IS 'Сколько заказов показывать (1-20)';
COMMENT ON COLUMN pickup_display_settings.auto_complete_seconds IS 'Автовыдача через N секунд после ready (NULL = вручную)';
COMMENT ON COLUMN pickup_display_settings.sound_enabled IS 'Звуковое оповещение при готовности';
COMMENT ON COLUMN pickup_display_settings.welcome_message IS 'Приветственное сообщение';
COMMENT ON COLUMN pickup_display_settings.is_active IS 'Активность настроек';
COMMENT ON COLUMN pickup_display_settings.created_at IS 'Дата создания';
COMMENT ON COLUMN pickup_display_settings.updated_at IS 'Дата обновления';

CREATE INDEX idx_pickup_display_settings_tenant ON pickup_display_settings(tenant_id);
CREATE INDEX idx_pickup_display_settings_device ON pickup_display_settings(device_id);
CREATE INDEX idx_pickup_display_settings_active ON pickup_display_settings(tenant_id, is_active) WHERE is_active = TRUE;

CREATE TRIGGER trg_pickup_display_settings_updated_at
    BEFORE UPDATE ON pickup_display_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ЧАСТЬ B: ТАБЛИЦА pickup_calls
-- ============================================================================

CREATE TABLE IF NOT EXISTS pickup_calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id) ON DELETE SET NULL,
    called_by UUID REFERENCES users(id) ON DELETE SET NULL,
    call_type VARCHAR(50) NOT NULL DEFAULT 'ready',
    called_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT chk_call_type CHECK (call_type IN ('ready', 'reminder'))
);

COMMENT ON TABLE pickup_calls IS 'История вызовов клиентов к стойке выдачи';
COMMENT ON COLUMN pickup_calls.id IS 'Уникальный идентификатор вызова';
COMMENT ON COLUMN pickup_calls.order_id IS 'Заказ';
COMMENT ON COLUMN pickup_calls.tenant_id IS 'Тенант (точка продаж)';
COMMENT ON COLUMN pickup_calls.device_id IS 'Устройство с которого был вызов';
COMMENT ON COLUMN pickup_calls.called_by IS 'Пользователь нажавший "Вызвать"';
COMMENT ON COLUMN pickup_calls.call_type IS 'Тип: ready (готов) или reminder (повторный)';
COMMENT ON COLUMN pickup_calls.called_at IS 'Время вызова';
COMMENT ON COLUMN pickup_calls.acknowledged_at IS 'Когда клиент подтвердил получение';

CREATE INDEX idx_pickup_calls_order ON pickup_calls(order_id);
CREATE INDEX idx_pickup_calls_tenant_created ON pickup_calls(tenant_id, called_at DESC);
CREATE INDEX idx_pickup_calls_unacknowledged ON pickup_calls(order_id, called_at) WHERE acknowledged_at IS NULL;

-- ============================================================================
-- ЧАСТЬ C: ТАБЛИЦА pickup_events
-- ============================================================================

CREATE TABLE IF NOT EXISTS pickup_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    device_id UUID REFERENCES devices(id) ON DELETE SET NULL,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    meta JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_event_type CHECK (event_type IN ('ready', 'called', 'qr_scanned', 'issued', 'timeout', 'not_picked_up'))
);

COMMENT ON TABLE pickup_events IS 'Лог событий выдачи для аналитики';
COMMENT ON COLUMN pickup_events.id IS 'Уникальный идентификатор события';
COMMENT ON COLUMN pickup_events.order_id IS 'Заказ';
COMMENT ON COLUMN pickup_events.tenant_id IS 'Тенант (точка продаж)';
COMMENT ON COLUMN pickup_events.event_type IS 'Тип события: ready, called, qr_scanned, issued, timeout, not_picked_up';
COMMENT ON COLUMN pickup_events.device_id IS 'Устройство';
COMMENT ON COLUMN pickup_events.created_by IS 'Пользователь создавший событие';
COMMENT ON COLUMN pickup_events.meta IS 'Дополнительные данные (qr_token и т.д.)';
COMMENT ON COLUMN pickup_events.created_at IS 'Время события';

CREATE INDEX idx_pickup_events_order ON pickup_events(order_id);
CREATE INDEX idx_pickup_events_tenant_created ON pickup_events(tenant_id, created_at DESC);
CREATE INDEX idx_pickup_events_type ON pickup_events(event_type);

-- ============================================================================
-- ЧАСТЬ D: РАСШИРЕНИЕ ТАБЛИЦЫ orders
-- ============================================================================

ALTER TABLE orders 
    ADD COLUMN IF NOT EXISTS ready_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS issued_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS pickup_method VARCHAR(50);

-- ИСПРАВЛЕНИЕ #1: DROP CONSTRAINT IF EXISTS + ADD CONSTRAINT (не IF NOT EXISTS)
ALTER TABLE orders
    DROP CONSTRAINT IF EXISTS chk_pickup_method;

ALTER TABLE orders
    ADD CONSTRAINT chk_pickup_method 
    CHECK (pickup_method IS NULL OR pickup_method IN ('qr', 'manual', 'auto'));

COMMENT ON COLUMN orders.ready_at IS 'Когда заказ стал ready';
COMMENT ON COLUMN orders.issued_at IS 'Когда заказ выдан';
COMMENT ON COLUMN orders.pickup_method IS 'Способ выдачи: qr, manual, auto';

CREATE INDEX IF NOT EXISTS idx_orders_ready_at ON orders(ready_at) WHERE ready_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_issued_at ON orders(issued_at) WHERE issued_at IS NOT NULL;

-- ============================================================================
-- ЧАСТЬ E: ТРИГГЕР на orders для timestamps
-- ============================================================================

CREATE OR REPLACE FUNCTION trg_fn_orders_pickup_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    -- Если статус стал ready — проставляем ready_at
    IF NEW.status = 'ready' AND OLD.status != 'ready' THEN
        IF NEW.ready_at IS NULL THEN
            NEW.ready_at := NOW();
        END IF;
    END IF;
    
    -- Если статус стал issued — проставляем issued_at
    IF NEW.status = 'issued' AND OLD.status != 'issued' THEN
        IF NEW.issued_at IS NULL THEN
            NEW.issued_at := NOW();
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_orders_pickup_timestamps ON orders;
CREATE TRIGGER trg_orders_pickup_timestamps
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_orders_pickup_timestamps();

-- ============================================================================
-- ЧАСТЬ F: ФУНКЦИИ ВЫДАЧИ
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: issue_order_by_qr
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION issue_order_by_qr(
    p_qr_token UUID,
    p_tenant_id UUID,
    p_device_id UUID,
    p_issued_by UUID DEFAULT NULL
)
RETURNS TABLE (
    order_id UUID,
    order_number VARCHAR(20)
) AS $$
DECLARE
    v_order RECORD;
BEGIN
    -- Находим заказ с блокировкой
    SELECT * INTO v_order
    FROM orders
    WHERE qr_token = p_qr_token
      AND tenant_id = p_tenant_id
      AND status = 'ready'
      AND qr_expires_at > NOW()
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заказ не найден, не готов или QR истёк';
    END IF;
    
    -- Обновляем заказ
    UPDATE orders
    SET status = 'issued',
        pickup_method = 'qr',
        updated_at = NOW()
    WHERE id = v_order.id;
    
    -- Записываем события
    INSERT INTO pickup_events (order_id, tenant_id, event_type, device_id, created_by, meta)
    VALUES (v_order.id, p_tenant_id, 'qr_scanned', p_device_id, p_issued_by, jsonb_build_object('qr_token', p_qr_token));
    
    INSERT INTO pickup_events (order_id, tenant_id, event_type, device_id, created_by)
    VALUES (v_order.id, p_tenant_id, 'issued', p_device_id, p_issued_by);
    
    -- Подтверждаем вызовы
    UPDATE pickup_calls
    SET acknowledged_at = NOW()
    WHERE order_id = v_order.id
      AND acknowledged_at IS NULL;
    
    -- Начисляем баллы лояльности если есть customer_id
    IF v_order.customer_id IS NOT NULL THEN
        PERFORM earn_loyalty_points(v_order.customer_id, v_order.id, p_tenant_id, v_order.final_amount);
    END IF;
    
    order_id := v_order.id;
    order_number := v_order.order_number;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: issue_order_manual
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION issue_order_manual(
    p_order_id UUID,
    p_tenant_id UUID,
    p_issued_by UUID
)
RETURNS VOID AS $$
DECLARE
    v_order RECORD;
BEGIN
    -- Находим заказ с блокировкой
    SELECT * INTO v_order
    FROM orders
    WHERE id = p_order_id
      AND tenant_id = p_tenant_id
      AND status = 'ready'
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заказ не найден или не готов';
    END IF;
    
    -- Обновляем заказ
    UPDATE orders
    SET status = 'issued',
        pickup_method = 'manual',
        updated_at = NOW()
    WHERE id = v_order.id;
    
    -- Записываем событие
    INSERT INTO pickup_events (order_id, tenant_id, event_type, created_by)
    VALUES (v_order.id, p_tenant_id, 'issued', p_issued_by);
    
    -- Подтверждаем вызовы
    UPDATE pickup_calls
    SET acknowledged_at = NOW()
    WHERE order_id = v_order.id
      AND acknowledged_at IS NULL;
    
    -- Начисляем баллы лояльности если есть customer_id
    IF v_order.customer_id IS NOT NULL THEN
        PERFORM earn_loyalty_points(v_order.customer_id, v_order.id, p_tenant_id, v_order.final_amount);
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: call_customer
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION call_customer(
    p_order_id UUID,
    p_tenant_id UUID,
    p_device_id UUID,
    p_called_by UUID DEFAULT NULL,
    p_call_type VARCHAR DEFAULT 'ready'
)
RETURNS UUID AS $$
DECLARE
    v_order RECORD;
    v_call_id UUID;
BEGIN
    -- Проверяем заказ
    SELECT * INTO v_order
    FROM orders
    WHERE id = p_order_id
      AND tenant_id = p_tenant_id
      AND status = 'ready';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заказ не найден или не готов';
    END IF;
    
    -- Создаём вызов
    INSERT INTO pickup_calls (order_id, tenant_id, device_id, called_by, call_type)
    VALUES (p_order_id, p_tenant_id, p_device_id, p_called_by, p_call_type)
    RETURNING id INTO v_call_id;
    
    -- Записываем событие
    INSERT INTO pickup_events (order_id, tenant_id, event_type, device_id, created_by)
    VALUES (p_order_id, p_tenant_id, 'called', p_device_id, p_called_by);
    
    -- Отправляем push-уведомление если есть customer_id
    IF v_order.customer_id IS NOT NULL THEN
        PERFORM queue_push_notification(
            v_order.customer_id,
            'Ваш заказ готов!',
            'Заказ ' || v_order.order_number || ' готов к выдаче',
            jsonb_build_object('order_id', v_order.id, 'order_number', v_order.order_number)
        );
    END IF;
    
    RETURN v_call_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: auto_complete_ready_orders
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION auto_complete_ready_orders(
    p_tenant_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_auto_complete_seconds INTEGER;
    v_order RECORD;
    v_count INTEGER := 0;
BEGIN
    -- Получаем настройку auto_complete_seconds
    SELECT auto_complete_seconds INTO v_auto_complete_seconds
    FROM pickup_display_settings
    WHERE tenant_id = p_tenant_id
      AND is_active = TRUE
    LIMIT 1;
    
    -- Если автовыдача выключена — выходим
    IF v_auto_complete_seconds IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Находим заказы которые нужно автовыдать
    FOR v_order IN
        SELECT id, customer_id, final_amount
        FROM orders
        WHERE tenant_id = p_tenant_id
          AND status = 'ready'
          AND ready_at < NOW() - (v_auto_complete_seconds || ' seconds')::INTERVAL
        FOR UPDATE
    LOOP
        -- Обновляем заказ
        UPDATE orders
        SET status = 'issued',
            pickup_method = 'auto',
            updated_at = NOW()
        WHERE id = v_order.id;
        
        -- Записываем событие
        INSERT INTO pickup_events (order_id, tenant_id, event_type, meta)
        VALUES (v_order.id, p_tenant_id, 'timeout', jsonb_build_object('auto_complete_seconds', v_auto_complete_seconds));
        
        -- Начисляем баллы лояльности если есть customer_id
        IF v_order.customer_id IS NOT NULL THEN
            PERFORM earn_loyalty_points(v_order.customer_id, v_order.id, p_tenant_id, v_order.final_amount);
        END IF;
        
        v_count := v_count + 1;
    END LOOP;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: get_pickup_queue
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_pickup_queue(
    p_tenant_id UUID
)
RETURNS TABLE (
    order_id UUID,
    order_number VARCHAR(20),
    customer_name TEXT,
    source VARCHAR(50),
    ready_at TIMESTAMP WITH TIME ZONE,
    wait_seconds INTEGER,
    call_count INTEGER,
    last_called_at TIMESTAMP WITH TIME ZONE,
    items_summary TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.id AS order_id,
        o.order_number,
        mc.first_name || ' ' || mc.last_name AS customer_name,
        o.source,
        o.ready_at,
        EXTRACT(EPOCH FROM (NOW() - o.ready_at))::INTEGER AS wait_seconds,
        (
            SELECT COUNT(*)
            FROM pickup_calls pc
            WHERE pc.order_id = o.id
        )::INTEGER AS call_count,
        (
            SELECT MAX(pc.called_at)
            FROM pickup_calls pc
            WHERE pc.order_id = o.id
        ) AS last_called_at,
        (
            SELECT STRING_AGG(p.name, ', ')
            FROM (
                SELECT p2.name
                FROM order_items oi2
                JOIN products p2 ON oi2.product_id = p2.id
                WHERE oi2.order_id = o.id
                ORDER BY oi2.quantity DESC
                LIMIT 2
            ) p
        ) AS items_summary
    FROM orders o
    LEFT JOIN mobile_customers mc ON o.customer_id = mc.id
    WHERE o.tenant_id = p_tenant_id
      AND o.status = 'ready'
    ORDER BY o.ready_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: get_pickup_stats
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_pickup_stats(
    p_tenant_id UUID,
    p_from TIMESTAMP WITH TIME ZONE,
    p_to TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
    orders_ready INTEGER,
    orders_issued INTEGER,
    orders_issued_qr INTEGER,
    orders_issued_manual INTEGER,
    orders_issued_auto INTEGER,
    avg_wait_seconds NUMERIC,
    max_wait_seconds INTEGER,
    total_calls INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (
            SELECT COUNT(*)
            FROM orders o
            JOIN payments p ON p.order_id = o.id
            WHERE o.tenant_id = p_tenant_id
              AND o.ready_at >= p_from
              AND o.ready_at <= p_to
              AND p.status = 'paid'
        )::INTEGER AS orders_ready,
        
        (
            SELECT COUNT(*)
            FROM orders o
            JOIN payments p ON p.order_id = o.id
            WHERE o.tenant_id = p_tenant_id
              AND o.issued_at >= p_from
              AND o.issued_at <= p_to
              AND p.status = 'paid'
        )::INTEGER AS orders_issued,
        
        (
            SELECT COUNT(*)
            FROM orders o
            JOIN payments p ON p.order_id = o.id
            WHERE o.tenant_id = p_tenant_id
              AND o.issued_at >= p_from
              AND o.issued_at <= p_to
              AND o.pickup_method = 'qr'
              AND p.status = 'paid'
        )::INTEGER AS orders_issued_qr,
        
        (
            SELECT COUNT(*)
            FROM orders o
            JOIN payments p ON p.order_id = o.id
            WHERE o.tenant_id = p_tenant_id
              AND o.issued_at >= p_from
              AND o.issued_at <= p_to
              AND o.pickup_method = 'manual'
              AND p.status = 'paid'
        )::INTEGER AS orders_issued_manual,
        
        (
            SELECT COUNT(*)
            FROM orders o
            JOIN payments p ON p.order_id = o.id
            WHERE o.tenant_id = p_tenant_id
              AND o.issued_at >= p_from
              AND o.issued_at <= p_to
              AND o.pickup_method = 'auto'
              AND p.status = 'paid'
        )::INTEGER AS orders_issued_auto,
        
        (
            SELECT AVG(EXTRACT(EPOCH FROM (o.issued_at - o.ready_at)))
            FROM orders o
            JOIN payments p ON p.order_id = o.id
            WHERE o.tenant_id = p_tenant_id
              AND o.issued_at >= p_from
              AND o.issued_at <= p_to
              AND o.ready_at IS NOT NULL
              AND o.issued_at IS NOT NULL
              AND p.status = 'paid'
        ) AS avg_wait_seconds,
        
        (
            SELECT MAX(EXTRACT(EPOCH FROM (o.issued_at - o.ready_at)))::INTEGER
            FROM orders o
            JOIN payments p ON p.order_id = o.id
            WHERE o.tenant_id = p_tenant_id
              AND o.issued_at >= p_from
              AND o.issued_at <= p_to
              AND o.ready_at IS NOT NULL
              AND o.issued_at IS NOT NULL
              AND p.status = 'paid'
        ) AS max_wait_seconds,
        
        (
            SELECT COUNT(*)
            FROM pickup_calls pc
            WHERE pc.tenant_id = p_tenant_id
              AND pc.called_at >= p_from
              AND pc.called_at <= p_to
        )::INTEGER AS total_calls;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- ЧАСТЬ G: VIEWS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- VIEW: v_pickup_queue
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_pickup_queue AS
SELECT 
    o.tenant_id,
    o.id AS order_id,
    o.order_number,
    o.source,
    o.customer_id,
    mc.first_name || ' ' || mc.last_name AS customer_name,
    o.ready_at,
    ROUND(EXTRACT(EPOCH FROM (NOW() - o.ready_at)) / 60)::INTEGER AS wait_minutes,
    (
        SELECT COUNT(*)
        FROM pickup_calls pc
        WHERE pc.order_id = o.id
    )::INTEGER AS call_count,
    p.payment_method,
    p.status AS payment_status
FROM orders o
LEFT JOIN mobile_customers mc ON o.customer_id = mc.id
LEFT JOIN payments p ON p.order_id = o.id
WHERE o.status = 'ready'
ORDER BY o.ready_at ASC;

COMMENT ON VIEW v_pickup_queue IS 'Текущая очередь заказов к выдаче';

-- ----------------------------------------------------------------------------
-- VIEW: v_pickup_display
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_pickup_display AS
SELECT 
    o.tenant_id,
    o.id AS order_id,
    o.order_number,
    mc.first_name AS customer_display_name,
    o.status,
    o.ready_at,
    o.issued_at,
    EXISTS (
        SELECT 1
        FROM pickup_calls pc
        WHERE pc.order_id = o.id
          AND pc.acknowledged_at IS NULL
    ) AS is_called
FROM orders o
LEFT JOIN mobile_customers mc ON o.customer_id = mc.id
WHERE o.status IN ('ready', 'issued')
  AND o.ready_at >= NOW() - INTERVAL '2 hours'
ORDER BY o.ready_at DESC;

COMMENT ON VIEW v_pickup_display IS 'Данные для экрана выдачи (публичный, без авторизации)';

-- ============================================================================
-- ЧАСТЬ H: ROW LEVEL SECURITY (RLS)
-- ИСПРАВЛЕНИЕ #2: УК роли могут видеть все данные без tenant_id фильтра
-- ============================================================================

ALTER TABLE pickup_display_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE pickup_calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE pickup_events ENABLE ROW LEVEL SECURITY;

-- pickup_display_settings: read — все устройства тенанта + УК
CREATE POLICY rls_pickup_display_settings_read ON pickup_display_settings
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

-- pickup_display_settings: write — office_manager/УК
CREATE POLICY rls_pickup_display_settings_write ON pickup_display_settings
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

-- pickup_calls: read — barista/shift_manager/office_manager своего тенанта ИЛИ УК
-- ИСПРАВЛЕНИЕ #2: УК роли видят все данные без tenant_id фильтра
CREATE POLICY rls_pickup_calls_read ON pickup_calls
    FOR SELECT
    USING (
        (
            tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
            AND EXISTS (
                SELECT 1 FROM user_roles ur
                JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                AND r.code IN ('barista', 'shift_manager', 'office_manager')
            )
        )
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager')
        )
    );

-- pickup_calls: write — barista/shift_manager/office_manager своего тенанта ИЛИ УК
CREATE POLICY rls_pickup_calls_write ON pickup_calls
    FOR ALL
    USING (
        (
            tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
            AND EXISTS (
                SELECT 1 FROM user_roles ur
                JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                AND r.code IN ('barista', 'shift_manager', 'office_manager')
            )
        )
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager')
        )
    );

-- pickup_events: read — barista/shift_manager/office_manager своего тенанта ИЛИ УК
-- ИСПРАВЛЕНИЕ #2: УК роли видят все данные без tenant_id фильтра
CREATE POLICY rls_pickup_events_read ON pickup_events
    FOR SELECT
    USING (
        (
            tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
            AND EXISTS (
                SELECT 1 FROM user_roles ur
                JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                AND r.code IN ('barista', 'shift_manager', 'office_manager')
            )
        )
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager')
        )
    );

-- pickup_events: write — только через SECURITY DEFINER функции (нет write policy)

-- ============================================================================
-- ЧАСТЬ I: SEED DATA
-- ============================================================================

BEGIN;

SET LOCAL row_security = off;

-- 1. Добавляем device для экрана выдачи
-- ИСПРАВЛЕНИЕ #3: Указан явный conflict target (tenant_id, name)
INSERT INTO devices (tenant_id, device_type, name, is_active)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'pickup_display',
    'pickup_display_1',
    TRUE
)
ON CONFLICT (tenant_id, name) DO NOTHING;

-- 2. Добавляем настройки экрана выдачи
INSERT INTO pickup_display_settings (
    tenant_id, device_id, display_mode, show_order_items,
    items_visible_count, auto_complete_seconds, sound_enabled,
    welcome_message, is_active
)
SELECT 
    '00000000-0000-0000-0000-000000000001',
    d.id,
    'both',
    TRUE,
    8,
    300,
    TRUE,
    'Ваш заказ готов!',
    TRUE
FROM devices d
WHERE d.tenant_id = '00000000-0000-0000-0000-000000000001'
  AND d.device_type = 'pickup_display'
  AND d.name = 'pickup_display_1'
ON CONFLICT (tenant_id, device_id) DO UPDATE SET
    display_mode = EXCLUDED.display_mode,
    show_order_items = EXCLUDED.show_order_items,
    items_visible_count = EXCLUDED.items_visible_count,
    auto_complete_seconds = EXCLUDED.auto_complete_seconds,
    sound_enabled = EXCLUDED.sound_enabled,
    welcome_message = EXCLUDED.welcome_message,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

COMMIT;

-- ============================================================================
-- КОНЕЦ МИГРАЦИЙ ЭТАПА 10
-- ============================================================================

/*
================================================================================
ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ

1. КАК ВЫДАТЬ ЗАКАЗ ПО QR-КОДУ
   SELECT * FROM issue_order_by_qr('qr-token-uuid', 'tenant-uuid', 'device-uuid', 'user-uuid');

2. КАК ВЫДАТЬ ЗАКАЗ ВРУЧНУЮ
   SELECT issue_order_manual('order-uuid', 'tenant-uuid', 'user-uuid');

3. КАК ВЫЗВАТЬ КЛИЕНТА
   SELECT call_customer('order-uuid', 'tenant-uuid', 'device-uuid', 'user-uuid', 'ready');

4. КАК ЗАПУСТИТЬ АВТОВЫДАЧУ (cron)
   SELECT auto_complete_ready_orders('tenant-uuid');

5. КАК ПОЛУЧИТЬ ОЧЕРЕДЬ ВЫДАЧИ
   SELECT * FROM get_pickup_queue('tenant-uuid');

6. КАК ПОЛУЧИТЬ СТАТИСТИКУ ВЫДАЧИ
   SELECT * FROM get_pickup_stats('tenant-uuid', '2025-01-01', '2025-01-31');

================================================================================
ИСПРАВЛЕНИЯ В ЭТОЙ ВЕРСИИ (1.1)

1. ✅ ADD CONSTRAINT IF NOT EXISTS → DROP CONSTRAINT + ADD CONSTRAINT
   - PostgreSQL не поддерживает IF NOT EXISTS для CONSTRAINT
   - Сначала DROP CONSTRAINT IF EXISTS, потом ADD CONSTRAINT

2. ✅ RLS политики для УК ролей без tenant_id фильтра
   - Было: AND EXISTS (УК роли) — требовало tenant_id
   - Стало: (tenant_id = ... AND EXISTS (локальные роли)) OR EXISTS (УК роли)
   - УК роли видят все данные без ограничения по tenant_id

3. ✅ ON CONFLICT с явным conflict target
   - Было: ON CONFLICT DO NOTHING (без указания колонки)
   - Стало: ON CONFLICT (tenant_id, name) DO NOTHING
   - Надёжная работа при наличии уникального индекса

================================================================================
АРХИТЕКТУРНЫЕ ЗАМЕЧАНИЯ

1. ✅ Триггер trg_orders_pickup_timestamps — BEFORE UPDATE
2. ✅ FOR UPDATE в issue_order_by_qr и issue_order_manual
3. ✅ auto_complete_ready_orders — цикл FOR для каждого заказа
4. ✅ Начисление баллов только при customer_id IS NOT NULL
5. ✅ items_summary через STRING_AGG с LIMIT 2
6. ✅ get_pickup_stats только по payments.status='paid'
7. ✅ SECURITY DEFINER на всех функциях
8. ✅ CHECK constraints на все enum-поля
9. ✅ v_pickup_display — публичный view (последние 2 часа)
10. ✅ pickup_calls.acknowledged_at при выдаче заказа

================================================================================
*/
```
apps-fileview.texmex_20260501.02_p0
ядро 10 этап.txt
ядро 10 этап.txt. На экране.