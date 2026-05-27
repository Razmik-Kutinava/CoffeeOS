
```sql
-- ============================================================================
-- SQL МИГРАЦИИ ДЛЯ СИСТЕМЫ КОФЕЕН (POSTGRESQL)
-- ЭТАП 4: ЛОКАЛЬНЫЕ МОДУЛИ - ТАБЛО БАРИСТЫ И ТВ-БОРД
-- Версия 4.2 - Исправлены функции и триггеры
-- ============================================================================

-- ============================================================================
-- TABLE: order_cancel_reasons (справочник причин отмены)
-- Создаётся первой т.к. на неё будет FK из orders
-- ============================================================================

CREATE TABLE IF NOT EXISTS order_cancel_reasons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0
);

COMMENT ON TABLE order_cancel_reasons IS 'Справочник причин отмены заказов';
COMMENT ON COLUMN order_cancel_reasons.id IS 'Уникальный идентификатор причины';
COMMENT ON COLUMN order_cancel_reasons.code IS 'Код причины для использования в коде';
COMMENT ON COLUMN order_cancel_reasons.name IS 'Человекочитаемое название';
COMMENT ON COLUMN order_cancel_reasons.is_active IS 'Статус активности причины';
COMMENT ON COLUMN order_cancel_reasons.sort_order IS 'Порядок отображения в списке';

CREATE INDEX idx_cancel_reasons_code ON order_cancel_reasons(code);
CREATE INDEX idx_cancel_reasons_active ON order_cancel_reasons(is_active);
CREATE INDEX idx_cancel_reasons_sort ON order_cancel_reasons(sort_order);

-- Seed причин отмены
INSERT INTO order_cancel_reasons (code, name, is_active, sort_order) VALUES
('client_request', 'По просьбе клиента', TRUE, 1),
('ingredient_missing', 'Нет ингредиента', TRUE, 2),
('equipment_failure', 'Неисправность оборудования', TRUE, 3),
('payment_issue', 'Проблема с оплатой', TRUE, 4),
('other', 'Другое', TRUE, 5)
ON CONFLICT (code) DO NOTHING;

-- ============================================================================
-- TABLE: devices (реестр устройств точки)
-- ============================================================================

CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    device_type VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    device_token VARCHAR(255) UNIQUE,
    token_expires_at TIMESTAMP WITH TIME ZONE,
    last_seen_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    ip_address VARCHAR(50),
    meta JSONB,
    registered_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_device_type CHECK (device_type IN (
        'barista_tablet', 'tv_board', 'kiosk', 'smart_locker'
    ))
);

COMMENT ON TABLE devices IS 'Реестр устройств точки (планшеты, ТВ, киоски, локеры)';
COMMENT ON COLUMN devices.id IS 'Уникальный идентификатор устройства';
COMMENT ON COLUMN devices.tenant_id IS 'Тенант (точка продаж) которому принадлежит устройство';
COMMENT ON COLUMN devices.device_type IS 'Тип устройства: barista_tablet, tv_board, kiosk, smart_locker';
COMMENT ON COLUMN devices.name IS 'Человекочитаемое название ("Планшет бариста #1")';
COMMENT ON COLUMN devices.device_token IS 'Токен для аутентификации устройства';
COMMENT ON COLUMN devices.token_expires_at IS 'Срок действия токена';
COMMENT ON COLUMN devices.last_seen_at IS 'Последний heartbeat от устройства';
COMMENT ON COLUMN devices.is_active IS 'Включено/выключено администратором';
COMMENT ON COLUMN devices.ip_address IS 'Последний IP в локальной сети';
COMMENT ON COLUMN devices.meta IS 'Доп. данные: версия прошивки, модель и т.д.';
COMMENT ON COLUMN devices.registered_by IS 'Пользователь зарегистрировавший устройство';

CREATE INDEX idx_devices_tenant_id ON devices(tenant_id);
CREATE INDEX idx_devices_type ON devices(device_type);
CREATE INDEX idx_devices_active ON devices(is_active);
CREATE INDEX idx_devices_token ON devices(device_token) WHERE device_token IS NOT NULL;
CREATE INDEX idx_devices_last_seen ON devices(last_seen_at);
CREATE INDEX idx_devices_tenant_type ON devices(tenant_id, device_type);

-- ============================================================================
-- TABLE: device_sessions (активные подключения устройств)
-- ============================================================================

CREATE TABLE IF NOT EXISTS device_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    connected_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    disconnected_at TIMESTAMP WITH TIME ZONE,
    connection_type VARCHAR(20) DEFAULT 'websocket',
    client_ip VARCHAR(50),
    CONSTRAINT chk_connection_type CHECK (connection_type IN ('websocket', 'http', 'grpc'))
);

COMMENT ON TABLE device_sessions IS 'Активные подключения устройств к ядру';
COMMENT ON COLUMN device_sessions.id IS 'Уникальный идентификатор сессии';
COMMENT ON COLUMN device_sessions.device_id IS 'Устройство';
COMMENT ON COLUMN device_sessions.tenant_id IS 'Тенант (дублируется для быстрого доступа)';
COMMENT ON COLUMN device_sessions.connected_at IS 'Время подключения';
COMMENT ON COLUMN device_sessions.disconnected_at IS 'Время отключения (NULL = подключено сейчас)';
COMMENT ON COLUMN device_sessions.connection_type IS 'Тип соединения: websocket, http, grpc';
COMMENT ON COLUMN device_sessions.client_ip IS 'IP адрес клиента';

CREATE INDEX idx_device_sessions_device_id ON device_sessions(device_id);
CREATE INDEX idx_device_sessions_tenant_id ON device_sessions(tenant_id);
CREATE INDEX idx_device_sessions_active ON device_sessions(device_id, disconnected_at) 
    WHERE disconnected_at IS NULL;

-- ============================================================================
-- TABLE: tv_board_settings (настройки отображения ТВ-борда)
-- ============================================================================

CREATE TABLE IF NOT EXISTS tv_board_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE UNIQUE,
    show_order_count INTEGER NOT NULL DEFAULT 10,
    display_seconds_ready INTEGER NOT NULL DEFAULT 30,
    show_locker_cell BOOLEAN NOT NULL DEFAULT TRUE,
    theme VARCHAR(50) NOT NULL DEFAULT 'dark',
    custom_message TEXT,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_theme CHECK (theme IN ('dark', 'light', 'brand')),
    CONSTRAINT chk_show_order_count CHECK (show_order_count > 0 AND show_order_count <= 50),
    CONSTRAINT chk_display_seconds CHECK (display_seconds_ready > 0 AND display_seconds_ready <= 300)
);

COMMENT ON TABLE tv_board_settings IS 'Настройки отображения ТВ-борда на точке';
COMMENT ON COLUMN tv_board_settings.id IS 'Уникальный идентификатор настроек';
COMMENT ON COLUMN tv_board_settings.tenant_id IS 'Тенант (одна запись на точку)';
COMMENT ON COLUMN tv_board_settings.show_order_count IS 'Сколько заказов показывать одновременно';
COMMENT ON COLUMN tv_board_settings.display_seconds_ready IS 'Секунд показа заказа после статуса ready';
COMMENT ON COLUMN tv_board_settings.show_locker_cell IS 'Показывать номер ячейки локера';
COMMENT ON COLUMN tv_board_settings.theme IS 'Тема оформления: dark, light, brand';
COMMENT ON COLUMN tv_board_settings.custom_message IS 'Сообщение снизу экрана (акция, приветствие)';
COMMENT ON COLUMN tv_board_settings.updated_by IS 'Пользователь изменивший настройки';

CREATE INDEX idx_tv_board_settings_tenant ON tv_board_settings(tenant_id);

-- ============================================================================
-- ALTER TABLE: orders - добавляем cancel_reason_code и cancel_stage
-- ============================================================================

ALTER TABLE orders 
    ADD COLUMN IF NOT EXISTS cancel_reason_code VARCHAR(50),
    ADD COLUMN IF NOT EXISTS cancel_stage VARCHAR(50),
    ADD CONSTRAINT fk_orders_cancel_reason 
        FOREIGN KEY (cancel_reason_code) 
        REFERENCES order_cancel_reasons(code) 
        ON DELETE SET NULL;

COMMENT ON COLUMN orders.cancel_reason_code IS 'Структурированная причина отмены (код из справочника)';
COMMENT ON COLUMN orders.cancel_stage IS 'Этап на котором заказ был отменён';

CREATE INDEX IF NOT EXISTS idx_orders_cancel_reason ON orders(cancel_reason_code);
CREATE INDEX IF NOT EXISTS idx_orders_cancel_stage ON orders(cancel_stage);

-- ============================================================================
-- ALTER TABLE: order_status_log - добавляем device_id
-- ============================================================================

ALTER TABLE order_status_log 
    ADD COLUMN IF NOT EXISTS device_id UUID,
    ADD CONSTRAINT fk_status_log_device 
        FOREIGN KEY (device_id) 
        REFERENCES devices(id) 
        ON DELETE SET NULL;

COMMENT ON COLUMN order_status_log.device_id IS 'Устройство с которого пришло изменение статуса';

CREATE INDEX IF NOT EXISTS idx_order_status_log_device ON order_status_log(device_id);

-- ============================================================================
-- TRIGGER: Обновление updated_at для устройств (с защитой от heartbeat)
-- ИСПРАВЛЕНИЕ #2: Отдельная функция только для devices, не трогаем глобальную
-- ============================================================================

CREATE OR REPLACE FUNCTION update_devices_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    -- Heartbeat: меняется только last_seen_at и/или ip_address → не обновляем updated_at
    -- Проверяем что настройки устройства не изменились
    IF (OLD.name = NEW.name) AND
       (OLD.is_active = NEW.is_active) AND
       (OLD.device_token IS NOT DISTINCT FROM NEW.device_token) AND
       (OLD.device_type = NEW.device_type) AND
       (OLD.meta IS NOT DISTINCT FROM NEW.meta) AND
       (OLD.registered_by IS NOT DISTINCT FROM NEW.registered_by)
    THEN
        -- Это heartbeat, updated_at не трогаем
        RETURN NEW;
    END IF;
    
    -- Настройки устройства изменились → обновляем updated_at
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создаём триггер только для devices с отдельной функцией
DROP TRIGGER IF EXISTS trg_devices_updated_at ON devices;
CREATE TRIGGER trg_devices_updated_at
    BEFORE UPDATE ON devices
    FOR EACH ROW
    EXECUTE FUNCTION update_devices_updated_at();

-- ============================================================================
-- TRIGGER: Автоматическое продление токена устройства
-- ============================================================================

CREATE OR REPLACE FUNCTION trg_device_token_expiry_handler()
RETURNS TRIGGER AS $$
BEGIN
    -- Если token установлен и срок не задан → ставим 1 год
    IF NEW.device_token IS NOT NULL AND NEW.token_expires_at IS NULL THEN
        NEW.token_expires_at := NOW() + INTERVAL '1 year';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_device_token_expiry
    BEFORE INSERT OR UPDATE ON devices
    FOR EACH ROW
    EXECUTE FUNCTION trg_device_token_expiry_handler();

-- ============================================================================
-- VIEW: v_active_orders_for_barista — очередь для табло баристы
-- ============================================================================

CREATE OR REPLACE VIEW v_active_orders_for_barista AS
SELECT 
    o.id AS order_id,
    o.tenant_id,
    o.order_number,
    o.status,
    o.source,
    o.customer_name,
    o.locker_cell,
    o.created_at,
    EXTRACT(EPOCH FROM (NOW() - osl.created_at))::INTEGER AS seconds_in_status,
    osl.created_at AS status_changed_at,
    COALESCE(
        JSONB_AGG(
            JSONB_BUILD_OBJECT(
                'product_name', oi.product_name,
                'quantity', oi.quantity,
                'modifier_options', oi.modifier_options
            ) ORDER BY oi.id
        ) FILTER (WHERE oi.id IS NOT NULL),
        '[]'::JSONB
    ) AS items
FROM orders o
LEFT JOIN order_items oi ON o.id = oi.order_id
LEFT JOIN LATERAL (
    SELECT created_at
    FROM order_status_log
    WHERE order_id = o.id
    ORDER BY created_at DESC
    LIMIT 1
) osl ON TRUE
WHERE o.status IN ('accepted', 'preparing', 'ready')
GROUP BY o.id, o.tenant_id, o.order_number, o.status, o.source, o.customer_name, 
         o.locker_cell, o.created_at, osl.created_at
ORDER BY o.created_at ASC;

COMMENT ON VIEW v_active_orders_for_barista IS 'Очередь активных заказов для табло баристы с позициями';

-- ============================================================================
-- VIEW: v_active_orders_for_tv — для ТВ-борда (публичный экран)
-- ============================================================================

CREATE OR REPLACE VIEW v_active_orders_for_tv AS
SELECT 
    o.id AS order_id,
    o.tenant_id,
    o.order_number,
    o.status,
    o.locker_cell,
    ready_log.created_at AS ready_at,
    EXTRACT(EPOCH FROM (NOW() - COALESCE(ready_log.created_at, o.created_at)))::INTEGER AS seconds_since_ready
FROM orders o
LEFT JOIN LATERAL (
    SELECT created_at
    FROM order_status_log
    WHERE order_id = o.id AND status_to = 'ready'
    ORDER BY created_at DESC
    LIMIT 1
) ready_log ON TRUE
WHERE o.status IN ('preparing', 'ready', 'issued')
ORDER BY 
    CASE WHEN o.status = 'ready' THEN 0 ELSE 1 END,
    o.created_at ASC;

COMMENT ON VIEW v_active_orders_for_tv IS 'Заказы для ТВ-борда (публичный экран, без деталей)';

-- ============================================================================
-- VIEW: v_device_status — состояние устройств точки
-- ============================================================================

CREATE OR REPLACE VIEW v_device_status AS
SELECT 
    d.id AS device_id,
    d.name,
    d.device_type,
    d.is_active,
    d.last_seen_at,
    (d.last_seen_at > NOW() - INTERVAL '2 minutes') AS is_online,
    d.tenant_id,
    t.name AS tenant_name,
    d.ip_address,
    d.meta,
    ds.connected_at AS session_started_at,
    ds.client_ip AS session_ip
FROM devices d
JOIN tenants t ON d.tenant_id = t.id
LEFT JOIN LATERAL (
    SELECT connected_at, client_ip
    FROM device_sessions
    WHERE device_id = d.id AND disconnected_at IS NULL
    ORDER BY connected_at DESC
    LIMIT 1
) ds ON TRUE;

COMMENT ON VIEW v_device_status IS 'Состояние устройств точки с онлайн-статусом';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tv_board_settings ENABLE ROW LEVEL SECURITY;

-- Политика для devices
CREATE POLICY rls_tenant_devices ON devices
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

-- Политика для device_sessions
CREATE POLICY rls_tenant_device_sessions ON device_sessions
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

-- Политика для tv_board_settings
CREATE POLICY rls_tenant_tv_board_settings ON tv_board_settings
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

-- Политика для order_cancel_reasons (read-only для всех, запись только УК)
ALTER TABLE order_cancel_reasons ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_cancel_reasons_read ON order_cancel_reasons
    FOR SELECT
    USING (TRUE);

CREATE POLICY rls_cancel_reasons_write ON order_cancel_reasons
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

-- ----------------------------------------------------------------------------
-- Функция: Аутентификация устройства по токену
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION authenticate_device(
    p_device_token VARCHAR(255)
)
RETURNS TABLE (
    device_id UUID,
    tenant_id UUID,
    device_type VARCHAR(50),
    is_active BOOLEAN,
    token_valid BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.tenant_id,
        d.device_type,
        d.is_active,
        (d.token_expires_at IS NULL OR d.token_expires_at > NOW()) AS token_valid
    FROM devices d
    WHERE d.device_token = p_device_token
      AND d.is_active = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- Функция: Обновить heartbeat устройства
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION device_heartbeat(
    p_device_id UUID,
    p_ip_address VARCHAR(50) DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE devices 
    SET last_seen_at = NOW(),
        ip_address = COALESCE(p_ip_address, ip_address)
    WHERE id = p_device_id;
    -- updated_at не обновляется благодаря триггеру update_devices_updated_at()
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- Функция: Изменить статус заказа (для бариста/менеджера)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION change_order_status(
    p_order_id UUID,
    p_new_status order_status,
    p_user_id UUID DEFAULT NULL,
    p_device_id UUID DEFAULT NULL,
    p_source VARCHAR(50) DEFAULT 'barista',
    p_comment TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_current_status order_status;
    v_tenant_id UUID;
    v_log_id UUID;
BEGIN
    -- Получаем текущий статус и тенант
    SELECT status, tenant_id INTO v_current_status, v_tenant_id
    FROM orders WHERE id = p_order_id;
    
    -- Проверка допустимого перехода статусов
    IF NOT (
        (v_current_status = 'accepted' AND p_new_status = 'preparing') OR
        (v_current_status = 'preparing' AND p_new_status = 'ready') OR
        (v_current_status = 'ready' AND p_new_status = 'issued') OR
        (v_current_status = 'issued' AND p_new_status = 'closed')
    ) THEN
        RAISE EXCEPTION 'Недопустимый переход статуса: % → %', v_current_status, p_new_status;
    END IF;
    
    -- Обновляем заказ
    UPDATE orders 
    SET status = p_new_status,
        updated_at = NOW()
    WHERE id = p_order_id;
    
    -- Пишем в лог с указанным источником
    INSERT INTO order_status_log (order_id, status_from, status_to, changed_by, device_id, source, comment)
    VALUES (p_order_id, v_current_status, p_new_status, p_user_id, p_device_id, p_source, p_comment)
    RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- Функция: Отменить заказ с причиной
-- ИСПРАВЛЕНИЕ #1: Добавлен параметр p_source вместо хардкода 'barista'
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION cancel_order(
    p_order_id UUID,
    p_reason_code VARCHAR(50),
    p_user_id UUID DEFAULT NULL,
    p_device_id UUID DEFAULT NULL,
    p_source VARCHAR(50) DEFAULT 'barista',
    p_comment TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_current_status order_status;
BEGIN
    -- Получаем текущий статус
    SELECT status INTO v_current_status
    FROM orders WHERE id = p_order_id;
    
    -- Нельзя отменить уже закрытый или выданный заказ
    IF v_current_status IN ('issued', 'closed', 'cancelled') THEN
        RAISE EXCEPTION 'Нельзя отменить заказ в статусе %', v_current_status;
    END IF;
    
    -- Обновляем заказ
    UPDATE orders 
    SET status = 'cancelled',
        cancel_reason_code = p_reason_code,
        cancel_reason = p_comment,
        cancel_stage = v_current_status,
        updated_at = NOW()
    WHERE id = p_order_id;
    
    -- Пишем в лог с указанным источником
    INSERT INTO order_status_log (order_id, status_from, status_to, changed_by, device_id, source, comment)
    VALUES (p_order_id, v_current_status, 'cancelled', p_user_id, p_device_id, p_source, p_comment);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- Функция: Поставить продукт в ручной стоп (раскупили)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_product_sold_out(
    p_tenant_id UUID,
    p_product_id UUID,
    p_user_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE product_tenant_settings
    SET is_sold_out = TRUE,
        sold_out_reason = 'manual',
        updated_at = NOW()
    WHERE tenant_id = p_tenant_id
      AND product_id = p_product_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Настройки продукта не найдены для тенанта % и продукта %', p_tenant_id, p_product_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- SEED DATA: Первичное заполнение
-- ============================================================================

BEGIN;

SET LOCAL row_security = off;

-- 1. Устройства для тестового тенанта
INSERT INTO devices (tenant_id, device_type, name, is_active, registered_by)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'barista_tablet', 'Планшет бариста #1', TRUE, 
     '00000000-0000-0000-0000-000000000001'),
    ('00000000-0000-0000-0000-000000000001', 'tv_board', 'ТВ в зале', TRUE,
     '00000000-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;

-- 2. Настройки ТВ-борда для тестового тенанта
INSERT INTO tv_board_settings (tenant_id, show_order_count, display_seconds_ready, show_locker_cell, theme, updated_by)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    10,
    30,
    TRUE,
    'dark',
    '00000000-0000-0000-0000-000000000001'
)
ON CONFLICT (tenant_id) DO UPDATE SET
    show_order_count = EXCLUDED.show_order_count,
    display_seconds_ready = EXCLUDED.display_seconds_ready,
    show_locker_cell = EXCLUDED.show_locker_cell,
    theme = EXCLUDED.theme,
    updated_at = NOW();

COMMIT;

-- ============================================================================
-- КОНЕЦ МИГРАЦИЙ ЭТАПА 4
-- ============================================================================

/*
================================================================================
ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ

1. КАК ЗАРЕГИСТРИРОВАТЬ НОВОЕ УСТРОЙСТВО

   INSERT INTO devices (tenant_id, device_type, name, device_token, registered_by)
   VALUES (
       'tenant-uuid-here',
       'barista_tablet',
       'Планшет бариста #2',
       'secure-random-token-here',
       'user-uuid-here'
   );
   -- Токен автоматически получит expiry = NOW() + 1 год

2. КАК WEBSOCKET КЛИЕНТ ДОЛЖЕН АУТЕНТИФИЦИРОВАТЬСЯ

   -- Шаг 1: При подключении отправить токен в заголовке
   Authorization: Bearer <device_token>
   
   -- Шаг 2: Сервер вызывает функцию аутентификации
   SELECT * FROM authenticate_device('device-token-here');
   
   -- Шаг 3: Если token_valid = TRUE и is_active = TRUE → разрешить подключение
   
   -- Шаг 4: Создать запись в device_sessions
   INSERT INTO device_sessions (device_id, tenant_id, client_ip)
   VALUES ('device-uuid', 'tenant-uuid', '192.168.1.100');
   
   -- Шаг 5: Обновлять heartbeat каждые 30-60 секунд
   SELECT device_heartbeat('device-uuid', '192.168.1.100');

3. КАК МЕНЯТЬ СТАТУС ЗАКАЗА (бариста или shift_manager)

   -- accepted → preparing (бариста)
   SELECT change_order_status(
       'order-uuid-here',
       'preparing',
       'user-uuid-here',
       'device-uuid-here',
       'barista',           -- источник: barista или shift_manager
       'Начинаю готовить'
   );
   
   -- preparing → ready
   SELECT change_order_status(
       'order-uuid-here',
       'ready',
       'user-uuid-here',
       'device-uuid-here',
       'barista',
       'Готов, ячейка 5'
   );

4. КАК ОТМЕНИТЬ ЗАКАЗ (бариста или shift_manager)
   ИСПРАВЛЕНИЕ #1: Теперь можно указать источник отмены

   SELECT cancel_order(
       'order-uuid-here',
       'ingredient_missing',  -- код причины из order_cancel_reasons
       'user-uuid-here',
       'device-uuid-here',
       'shift_manager',       -- источник: barista или shift_manager
       'Закончилось овсяное молоко'
   );

5. КАК РАБОТАЕТ DEVICE HEARTBEAT
   ИСПРАВЛЕНИЕ #2: Отдельный триггер для devices не обновляет updated_at при heartbeat

   -- Устройство отправляет ping каждые 30-60 секунд:
   SELECT device_heartbeat('device-uuid', '192.168.1.100');
   
   -- Триггер update_devices_updated_at() проверяет:
   -- Если изменились только last_seen_at и/или ip_address → updated_at НЕ меняется
   -- Если изменились name, is_active, device_token, meta → updated_at = NOW()
   
   -- v_device_status показывает is_online = TRUE если:
   -- last_seen_at > NOW() - INTERVAL '2 minutes'

6. КАК ПОСТАВИТЬ ПРОДУКТ В СТОП ("РАСКУПИЛИ")

   SELECT set_product_sold_out(
       'tenant-uuid-here',
       'product-uuid-here',
       'user-uuid-here'
   );

7. ПОЛУЧЕНИЕ ДАННЫХ ДЛЯ ТАБЛО БАРИСТЫ

   SELECT * FROM v_active_orders_for_barista
   WHERE tenant_id = 'tenant-uuid-here'
   ORDER BY created_at ASC;

8. ПОЛУЧЕНИЕ ДАННЫХ ДЛЯ ТВ-БОРДА

   SELECT * FROM v_active_orders_for_tv
   WHERE tenant_id = 'tenant-uuid-here'
   ORDER BY seconds_since_ready ASC;

================================================================================
ИСПРАВЛЕНИЯ В ЭТОЙ ВЕРСИИ

1. ✅ Функция cancel_order теперь принимает параметр p_source
   - Можно указывать 'barista' или 'shift_manager'
   - В order_status_log записывается корректный источник отмены
   - По умолчанию 'barista' для обратной совместимости

2. ✅ Логика heartbeat вынесена в отдельную функцию update_devices_updated_at()
   - Глобальная update_updated_at_column() НЕ тронута
   - Этапы 0-3 продолжают работать со своей функцией
   - При пересоздании миграций этапов 0-3 ничего не сломается

3. ✅ ip_address исключён из проверки изменений настроек устройства
   - В update_devices_updated_at() проверяются только:
     name, is_active, device_token, device_type, meta, registered_by
   - Изменение ip_address при heartbeat НЕ влияет на updated_at
   - updated_at отражает только изменения конфигурации устройства

================================================================================
АРХИТЕКТУРНЫЕ ЗАМЕЧАНИЯ

1. ✅ Разделение триггеров — безопасный паттерн для расширяемой системы
   - update_updated_at_column() — для всех таблиц кроме devices
   - update_devices_updated_at() — только для devices с логикой heartbeat
   - Этапы независимы, можно перезапускать по отдельности

2. ✅ source параметризован во всех функциях изменения состояния
   - change_order_status: p_source DEFAULT 'barista'
   - cancel_order: p_source DEFAULT 'barista'
   - Можно точно определить кто инициировал изменение

3. ✅ updated_at на devices теперь имеет смысл
   - Меняется только при изменении настроек устройства
   - Не "шумит" от heartbeat каждые 30 секунд
   - Можно отслеживать когда устройство было перенастроено

================================================================================
*/
```
apps-fileview.texmex_20260501.02_p0
ядро 4 этап.txt
ядро 4 этап.txt. На экране.