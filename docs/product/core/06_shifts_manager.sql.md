
```sql
-- ============================================================================
-- SQL МИГРАЦИИ ДЛЯ СИСТЕМЫ КОФЕЕН (POSTGRESQL)
-- ЭТАП 7: СМЕНЫ + УПРАВЛЯЮЩИЙ (SHIFTS + MANAGER)
-- Версия 1.1 - Исправлены RLS read-политики
-- ============================================================================

-- ============================================================================
-- ЧАСТЬ A: РАСШИРЕНИЕ ТАБЛИЦЫ shifts
-- ============================================================================

ALTER TABLE shifts 
    ADD COLUMN IF NOT EXISTS status VARCHAR(50) NOT NULL DEFAULT 'open',
    ADD COLUMN IF NOT EXISTS note TEXT,
    ADD COLUMN IF NOT EXISTS opening_cash DECIMAL(10,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS closing_cash DECIMAL(10,2),
    ADD COLUMN IF NOT EXISTS expected_cash DECIMAL(10,2),
    ADD COLUMN IF NOT EXISTS cash_difference DECIMAL(10,2),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW();

ALTER TABLE shifts 
    DROP CONSTRAINT IF EXISTS chk_shifts_status;

ALTER TABLE shifts 
    ADD CONSTRAINT chk_shifts_status 
    CHECK (status IN ('open', 'closed', 'cancelled'));

ALTER TABLE shifts 
    DROP CONSTRAINT IF EXISTS chk_shifts_opening_cash;

ALTER TABLE shifts 
    ADD CONSTRAINT chk_shifts_opening_cash 
    CHECK (opening_cash >= 0);

ALTER TABLE shifts 
    DROP CONSTRAINT IF EXISTS chk_shifts_closing_cash;

ALTER TABLE shifts 
    ADD CONSTRAINT chk_shifts_closing_cash 
    CHECK (closing_cash IS NULL OR closing_cash >= 0);

COMMENT ON COLUMN shifts.status IS 'Статус смены: open, closed, cancelled';
COMMENT ON COLUMN shifts.note IS 'Комментарий управляющего при открытии/закрытии';
COMMENT ON COLUMN shifts.opening_cash IS 'Касса на начало смены';
COMMENT ON COLUMN shifts.closing_cash IS 'Касса на конец смены (факт)';
COMMENT ON COLUMN shifts.expected_cash IS 'Касса на конец смены (по системе)';
COMMENT ON COLUMN shifts.cash_difference IS 'Расхождение (closing_cash - expected_cash)';

CREATE INDEX IF NOT EXISTS idx_shifts_tenant_status ON shifts(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_shifts_opened_at ON shifts(tenant_id, opened_at DESC);
CREATE INDEX IF NOT EXISTS idx_shifts_status ON shifts(status);

DROP INDEX IF EXISTS idx_shifts_one_open_per_tenant;
CREATE UNIQUE INDEX idx_shifts_one_open_per_tenant 
    ON shifts(tenant_id) 
    WHERE status = 'open';

DROP TRIGGER IF EXISTS trg_shifts_updated_at ON shifts;
CREATE TRIGGER trg_shifts_updated_at
    BEFORE UPDATE ON shifts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ЧАСТЬ B: НОВАЯ ТАБЛИЦА shift_staff
-- ============================================================================

CREATE TABLE IF NOT EXISTS shift_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    role_in_shift VARCHAR(50) NOT NULL,
    checked_in_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    checked_out_at TIMESTAMP WITH TIME ZONE,
    note TEXT,
    UNIQUE(shift_id, user_id),
    CONSTRAINT chk_shift_staff_role CHECK (role_in_shift IN ('barista', 'shift_manager'))
);

COMMENT ON TABLE shift_staff IS 'Привязка сотрудников к смене';
COMMENT ON COLUMN shift_staff.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN shift_staff.shift_id IS 'Смена';
COMMENT ON COLUMN shift_staff.user_id IS 'Сотрудник';
COMMENT ON COLUMN shift_staff.tenant_id IS 'Тенант (точка продаж)';
COMMENT ON COLUMN shift_staff.role_in_shift IS 'Роль в смене: barista, shift_manager';
COMMENT ON COLUMN shift_staff.checked_in_at IS 'Время прихода на смену';
COMMENT ON COLUMN shift_staff.checked_out_at IS 'Время ухода со смены';
COMMENT ON COLUMN shift_staff.note IS 'Комментарий';

CREATE INDEX idx_shift_staff_shift ON shift_staff(shift_id);
CREATE INDEX idx_shift_staff_user ON shift_staff(user_id);
CREATE INDEX idx_shift_staff_tenant ON shift_staff(tenant_id);
CREATE INDEX idx_shift_staff_active ON shift_staff(shift_id, checked_out_at) WHERE checked_out_at IS NULL;

-- ============================================================================
-- ЧАСТЬ C: НОВАЯ ТАБЛИЦА shift_cash_operations
-- ============================================================================

CREATE TABLE IF NOT EXISTS shift_cash_operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    operation_type VARCHAR(50) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    note TEXT,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_cash_op_type CHECK (operation_type IN ('deposit', 'withdrawal', 'collection')),
    CONSTRAINT chk_cash_op_amount CHECK (amount > 0)
);

COMMENT ON TABLE shift_cash_operations IS 'Кассовые операции внутри смены';
COMMENT ON COLUMN shift_cash_operations.id IS 'Уникальный идентификатор операции';
COMMENT ON COLUMN shift_cash_operations.shift_id IS 'Смена';
COMMENT ON COLUMN shift_cash_operations.tenant_id IS 'Тенант (точка продаж)';
COMMENT ON COLUMN shift_cash_operations.operation_type IS 'Тип: deposit (внесение), withdrawal (изъятие), collection (инкассация)';
COMMENT ON COLUMN shift_cash_operations.amount IS 'Сумма операции (всегда положительная)';
COMMENT ON COLUMN shift_cash_operations.note IS 'Комментарий к операции';
COMMENT ON COLUMN shift_cash_operations.created_by IS 'Пользователь создавший операцию';

CREATE INDEX idx_shift_cash_ops_shift ON shift_cash_operations(shift_id);
CREATE INDEX idx_shift_cash_ops_tenant ON shift_cash_operations(tenant_id);
CREATE INDEX idx_shift_cash_ops_type ON shift_cash_operations(operation_type);
CREATE INDEX idx_shift_cash_ops_created_at ON shift_cash_operations(created_at);

-- ============================================================================
-- ЧАСТЬ D: ФУНКЦИИ УПРАВЛЕНИЯ СМЕНОЙ
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: open_shift
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION open_shift(
    p_tenant_id UUID,
    p_opened_by UUID,
    p_opening_cash DECIMAL(10,2) DEFAULT 0,
    p_note TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_shift_id UUID;
BEGIN
    -- Проверяем что нет другой открытой смены
    PERFORM 1 FROM shifts
    WHERE tenant_id = p_tenant_id
      AND status = 'open'
    FOR UPDATE;
    
    IF FOUND THEN
        RAISE EXCEPTION 'Уже есть открытая смена на этой точке';
    END IF;
    
    -- Создаём новую смену
    INSERT INTO shifts (
        tenant_id, opened_by, opened_at, status,
        opening_cash, note
    ) VALUES (
        p_tenant_id, p_opened_by, NOW(), 'open',
        p_opening_cash, p_note
    )
    RETURNING id INTO v_shift_id;
    
    -- Добавляем открывшего смену в staff
    INSERT INTO shift_staff (shift_id, user_id, tenant_id, role_in_shift)
    SELECT 
        v_shift_id,
        p_opened_by,
        p_tenant_id,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM user_roles ur
                JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = p_opened_by 
                  AND ur.tenant_id = p_tenant_id
                  AND r.code = 'shift_manager'
            ) THEN 'shift_manager'
            ELSE 'barista'
        END;
    
    RETURN v_shift_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: close_shift
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION close_shift(
    p_shift_id UUID,
    p_closed_by UUID,
    p_closing_cash DECIMAL(10,2),
    p_note TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_shift RECORD;
    v_opening_cash DECIMAL(10,2);
    v_cash_payments DECIMAL(10,2);
    v_deposits DECIMAL(10,2);
    v_withdrawals DECIMAL(10,2);
    v_collections DECIMAL(10,2);
    v_expected_cash DECIMAL(10,2);
    v_cash_difference DECIMAL(10,2);
BEGIN
    -- Блокируем смену для защиты от race condition
    SELECT * INTO v_shift
    FROM shifts
    WHERE id = p_shift_id
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Смена не найдена';
    END IF;
    
    IF v_shift.status != 'open' THEN
        RAISE EXCEPTION 'Смена уже закрыта или отменена (статус: %)', v_shift.status;
    END IF;
    
    v_opening_cash := COALESCE(v_shift.opening_cash, 0);
    
    -- Считаем наличные платежи за время смены
    SELECT COALESCE(SUM(p.amount), 0) INTO v_cash_payments
    FROM payments p
    WHERE p.tenant_id = v_shift.tenant_id
      AND p.payment_method = 'cash'
      AND p.status = 'paid'
      AND p.created_at >= v_shift.opened_at;
    
    -- Считаем кассовые операции
    SELECT COALESCE(SUM(amount), 0) INTO v_deposits
    FROM shift_cash_operations
    WHERE shift_id = p_shift_id
      AND operation_type = 'deposit';
    
    SELECT COALESCE(SUM(amount), 0) INTO v_withdrawals
    FROM shift_cash_operations
    WHERE shift_id = p_shift_id
      AND operation_type = 'withdrawal';
    
    SELECT COALESCE(SUM(amount), 0) INTO v_collections
    FROM shift_cash_operations
    WHERE shift_id = p_shift_id
      AND operation_type = 'collection';
    
    -- Ожидаемая касса = opening + cash_payments + deposits - withdrawals - collections
    v_expected_cash := v_opening_cash + v_cash_payments + v_deposits - v_withdrawals - v_collections;
    v_cash_difference := p_closing_cash - v_expected_cash;
    
    -- Закрываем смену
    UPDATE shifts
    SET status = 'closed',
        closed_by = p_closed_by,
        closed_at = NOW(),
        closing_cash = p_closing_cash,
        expected_cash = v_expected_cash,
        cash_difference = v_cash_difference,
        note = COALESCE(p_note, note),
        updated_at = NOW()
    WHERE id = p_shift_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: add_shift_staff
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_shift_staff(
    p_shift_id UUID,
    p_user_id UUID,
    p_tenant_id UUID,
    p_role VARCHAR(50)
)
RETURNS VOID AS $$
BEGIN
    -- Проверяем что смена существует и открыта
    PERFORM 1 FROM shifts
    WHERE id = p_shift_id
      AND tenant_id = p_tenant_id
      AND status = 'open';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Смена не найдена или закрыта';
    END IF;
    
    -- Добавляем или обновляем сотрудника
    INSERT INTO shift_staff (shift_id, user_id, tenant_id, role_in_shift)
    VALUES (p_shift_id, p_user_id, p_tenant_id, p_role)
    ON CONFLICT (shift_id, user_id) DO UPDATE
    SET role_in_shift = EXCLUDED.role_in_shift,
        checked_out_at = NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: checkout_shift_staff
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION checkout_shift_staff(
    p_shift_id UUID,
    p_user_id UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE shift_staff
    SET checked_out_at = NOW()
    WHERE shift_id = p_shift_id
      AND user_id = p_user_id
      AND checked_out_at IS NULL;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Сотрудник не найден в активной смене';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: add_cash_operation
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_cash_operation(
    p_shift_id UUID,
    p_tenant_id UUID,
    p_operation_type VARCHAR(50),
    p_amount DECIMAL(10,2),
    p_created_by UUID,
    p_note TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_operation_id UUID;
BEGIN
    -- Проверяем что смена существует и открыта
    PERFORM 1 FROM shifts
    WHERE id = p_shift_id
      AND tenant_id = p_tenant_id
      AND status = 'open';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Смена не найдена или закрыта';
    END IF;
    
    -- Создаём операцию
    INSERT INTO shift_cash_operations (
        shift_id, tenant_id, operation_type, amount, created_by, note
    ) VALUES (
        p_shift_id, p_tenant_id, p_operation_type, p_amount, p_created_by, p_note
    )
    RETURNING id INTO v_operation_id;
    
    RETURN v_operation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ЧАСТЬ E: ФУНКЦИИ УПРАВЛЯЮЩЕГО (отчёты и контроль)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: get_shift_summary
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_shift_summary(
    p_shift_id UUID
)
RETURNS TABLE (
    shift_id UUID,
    tenant_id UUID,
    opened_at TIMESTAMP WITH TIME ZONE,
    closed_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50),
    opening_cash DECIMAL(10,2),
    closing_cash DECIMAL(10,2),
    expected_cash DECIMAL(10,2),
    cash_difference DECIMAL(10,2),
    orders_total_count INTEGER,
    orders_completed_count INTEGER,
    orders_cancelled_count INTEGER,
    revenue_card DECIMAL(10,2),
    revenue_cash DECIMAL(10,2),
    revenue_total DECIMAL(10,2),
    avg_order_amount DECIMAL(10,2),
    staff_count INTEGER
) AS $$
DECLARE
    v_shift RECORD;
    v_closed_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Получаем смену
    SELECT * INTO v_shift
    FROM shifts
    WHERE id = p_shift_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Смена не найдена';
    END IF;
    
    v_closed_at := COALESCE(v_shift.closed_at, NOW());
    
    -- Считаем заказы
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE o.status = 'issued'),
        COUNT(*) FILTER (WHERE o.status = 'cancelled')
    INTO 
        orders_total_count,
        orders_completed_count,
        orders_cancelled_count
    FROM orders o
    WHERE o.tenant_id = v_shift.tenant_id
      AND o.created_at >= v_shift.opened_at
      AND o.created_at <= v_closed_at;
    
    -- Считаем выручку (только paid платежи)
    SELECT 
        COALESCE(SUM(p.amount) FILTER (WHERE p.payment_method = 'card'), 0),
        COALESCE(SUM(p.amount) FILTER (WHERE p.payment_method = 'cash'), 0),
        COALESCE(SUM(p.amount), 0)
    INTO 
        revenue_card,
        revenue_cash,
        revenue_total
    FROM payments p
    WHERE p.tenant_id = v_shift.tenant_id
      AND p.status = 'paid'
      AND p.created_at >= v_shift.opened_at
      AND p.created_at <= v_closed_at;
    
    -- Средний чек
    IF orders_completed_count > 0 THEN
        avg_order_amount := revenue_total / orders_completed_count;
    ELSE
        avg_order_amount := 0;
    END IF;
    
    -- Количество сотрудников
    SELECT COUNT(DISTINCT user_id) INTO staff_count
    FROM shift_staff
    WHERE shift_id = p_shift_id;
    
    -- Возвращаем результат
    shift_id := v_shift.id;
    tenant_id := v_shift.tenant_id;
    opened_at := v_shift.opened_at;
    closed_at := v_shift.closed_at;
    status := v_shift.status;
    opening_cash := v_shift.opening_cash;
    closing_cash := v_shift.closing_cash;
    expected_cash := v_shift.expected_cash;
    cash_difference := v_shift.cash_difference;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: get_hourly_revenue
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_hourly_revenue(
    p_shift_id UUID
)
RETURNS TABLE (
    hour_start TIMESTAMP WITH TIME ZONE,
    orders_count INTEGER,
    revenue DECIMAL(10,2)
) AS $$
DECLARE
    v_shift RECORD;
    v_closed_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Получаем смену
    SELECT * INTO v_shift
    FROM shifts
    WHERE id = p_shift_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Смена не найдена';
    END IF;
    
    v_closed_at := COALESCE(v_shift.closed_at, NOW());
    
    -- Группируем по часам
    RETURN QUERY
    SELECT 
        date_trunc('hour', o.created_at) AS hour_start,
        COUNT(*)::INTEGER AS orders_count,
        COALESCE(SUM(o.final_amount), 0)::DECIMAL(10,2) AS revenue
    FROM orders o
    WHERE o.tenant_id = v_shift.tenant_id
      AND o.created_at >= v_shift.opened_at
      AND o.created_at <= v_closed_at
      AND o.status != 'cancelled'
    GROUP BY date_trunc('hour', o.created_at)
    ORDER BY hour_start;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- ЧАСТЬ F: VIEWS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- VIEW: v_current_shift
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_current_shift AS
SELECT 
    s.tenant_id,
    s.id AS shift_id,
    s.opened_at,
    s.opening_cash,
    u.first_name || ' ' || u.last_name AS opened_by_name,
    EXTRACT(EPOCH FROM (NOW() - s.opened_at)) / 60 AS duration_minutes,
    (
        SELECT COUNT(*) 
        FROM orders o 
        WHERE o.tenant_id = s.tenant_id 
          AND o.created_at >= s.opened_at
    ) AS orders_count,
    (
        SELECT COALESCE(SUM(o.final_amount), 0)
        FROM orders o
        WHERE o.tenant_id = s.tenant_id
          AND o.created_at >= s.opened_at
          AND o.status != 'cancelled'
    ) AS revenue_total,
    (
        SELECT COALESCE(
            JSONB_AGG(
                JSONB_BUILD_OBJECT(
                    'user_id', ss.user_id,
                    'name', u2.first_name || ' ' || u2.last_name,
                    'role', ss.role_in_shift,
                    'checked_in_at', ss.checked_in_at
                )
            ),
            '[]'::JSONB
        )
        FROM shift_staff ss
        JOIN users u2 ON ss.user_id = u2.id
        WHERE ss.shift_id = s.id
          AND ss.checked_out_at IS NULL
    ) AS staff_list
FROM shifts s
JOIN users u ON s.opened_by = u.id
WHERE s.status = 'open';

COMMENT ON VIEW v_current_shift IS 'Текущая открытая смена на точке';

-- ----------------------------------------------------------------------------
-- VIEW: v_shift_orders
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_shift_orders AS
SELECT 
    s.id AS shift_id,
    s.tenant_id,
    o.id AS order_id,
    o.order_number,
    o.status AS order_status,
    o.source,
    o.total_amount,
    o.final_amount,
    o.created_at,
    p.payment_method,
    p.status AS payment_status
FROM shifts s
JOIN orders o ON o.tenant_id = s.tenant_id
    AND o.created_at >= s.opened_at
    AND o.created_at <= COALESCE(s.closed_at, NOW())
LEFT JOIN payments p ON p.order_id = o.id
ORDER BY o.created_at DESC;

COMMENT ON VIEW v_shift_orders IS 'Заказы с привязкой к смене';

-- ============================================================================
-- ЧАСТЬ G: ROW LEVEL SECURITY (RLS)
-- ИСПРАВЛЕНИЕ: read-политики теперь требуют shift_manager/office_manager/УК
-- ============================================================================

ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_cash_operations ENABLE ROW LEVEL SECURITY;

-- shifts: read — все роли своего тенанта + УК
CREATE POLICY rls_shifts_read ON shifts
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

-- shifts: write — shift_manager, office_manager + УК
CREATE POLICY rls_shifts_write ON shifts
    FOR ALL
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        AND EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('shift_manager', 'office_manager', 'ук_global_admin', 'ук_country_manager')
        )
    );

-- shift_staff: ИСПРАВЛЕНИЕ — read только для shift_manager, office_manager + УК
-- barista НЕ должен видеть состав смены других сотрудников
CREATE POLICY rls_shift_staff_read ON shift_staff
    FOR SELECT
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        AND EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('shift_manager', 'office_manager', 'ук_global_admin', 'ук_country_manager')
        )
    );

CREATE POLICY rls_shift_staff_write ON shift_staff
    FOR ALL
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        AND EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('shift_manager', 'office_manager', 'ук_global_admin', 'ук_country_manager')
        )
    );

-- shift_cash_operations: ИСПРАВЛЕНИЕ — read только для shift_manager, office_manager + УК
-- barista НЕ должен видеть кассовые операции
CREATE POLICY rls_shift_cash_ops_read ON shift_cash_operations
    FOR SELECT
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        AND EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('shift_manager', 'office_manager', 'ук_global_admin', 'ук_country_manager')
        )
    );

CREATE POLICY rls_shift_cash_ops_write ON shift_cash_operations
    FOR ALL
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        AND EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('shift_manager', 'office_manager', 'ук_global_admin', 'ук_country_manager')
        )
    );

-- ============================================================================
-- ЧАСТЬ H: SEED DATA
-- ============================================================================

BEGIN;

SET LOCAL row_security = off;

-- 1. Открываем тестовую смену для тестового тенанта
INSERT INTO shifts (tenant_id, opened_by, opened_at, status, opening_cash, note)
SELECT 
    '00000000-0000-0000-0000-000000000001',
    u.id,
    NOW(),
    'open',
    1000.00,
    'Тестовая смена'
FROM users u
WHERE u.tenant_id = '00000000-0000-0000-0000-000000000001'
  AND EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.id
      WHERE ur.user_id = u.id
        AND ur.tenant_id = '00000000-0000-0000-0000-000000000001'
        AND r.code IN ('office_manager', 'shift_manager')
  )
LIMIT 1
ON CONFLICT DO NOTHING;

-- 2. Добавляем сотрудника в смену (barista)
INSERT INTO shift_staff (shift_id, user_id, tenant_id, role_in_shift)
SELECT 
    s.id,
    u.id,
    '00000000-0000-0000-0000-000000000001',
    'barista'
FROM shifts s
CROSS JOIN users u
WHERE s.tenant_id = '00000000-0000-0000-0000-000000000001'
  AND s.status = 'open'
  AND u.tenant_id = '00000000-0000-0000-0000-000000000001'
  AND EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.id
      WHERE ur.user_id = u.id
        AND ur.tenant_id = '00000000-0000-0000-0000-000000000001'
        AND r.code = 'barista'
  )
LIMIT 1
ON CONFLICT (shift_id, user_id) DO NOTHING;

COMMIT;

-- ============================================================================
-- КОНЕЦ МИГРАЦИЙ ЭТАПА 7
-- ============================================================================

/*
================================================================================
ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ

1. КАК ОТКРЫТЬ СМЕНУ
   SELECT open_shift('tenant-uuid', 'user-uuid', 1000.00, 'Утренняя смена');

2. КАК ДОБАВИТЬ СОТРУДНИКА В СМЕНУ
   SELECT add_shift_staff('shift-uuid', 'user-uuid', 'tenant-uuid', 'barista');

3. КАК ОТМЕТИТЬ УХОД СОТРУДНИКА
   SELECT checkout_shift_staff('shift-uuid', 'user-uuid');

4. КАК ДОБАВИТЬ КАССОВУЮ ОПЕРАЦИЮ
   SELECT add_cash_operation('shift-uuid', 'tenant-uuid', 'deposit', 5000.00, 'user-uuid', 'Сдача');

5. КАК ЗАКРЫТЬ СМЕНУ
   SELECT close_shift('shift-uuid', 'user-uuid', 53500.00, 'Всё ок');

6. КАК ПОЛУЧИТЬ ОТЧЁТ ПО СМЕНЕ
   SELECT * FROM get_shift_summary('shift-uuid');

7. КАК ПОЛУЧИТЬ ВЫРУЧКУ ПО ЧАСАМ
   SELECT * FROM get_hourly_revenue('shift-uuid');

8. КАК ПОСМОТРЕТЬ ТЕКУЩУЮ СМЕНУ
   SELECT * FROM v_current_shift WHERE tenant_id = 'tenant-uuid';

================================================================================
ИСПРАВЛЕНИЯ В ЭТОЙ ВЕРСИИ (1.1)

1. ✅ RLS read-политики на shift_staff и shift_cash_operations
   - Было: tenant_id = current_setting(...) — все пользователи тенанта
   - Стало: + EXISTS проверка на shift_manager/office_manager/УК роли
   - barista больше НЕ может читать состав смены и кассовые операции
   - Соответствует требованиям промпта

================================================================================
АРХИТЕКТУРНЫЕ ЗАМЕЧАНИЯ

1. ✅ Partial unique index на открытую смену (status='open')
2. ✅ FOR UPDATE в close_shift — защита от race condition
3. ✅ expected_cash считается по payments.status='paid' за время смены
4. ✅ shift_staff с checked_in_at/checked_out_at для учёта времени
5. ✅ Кассовые операции: deposit, withdrawal, collection
6. ✅ barista НЕ имеет доступа к shift_staff и shift_cash_operations (read/write)
7. ✅ get_shift_summary: выручка строго по payments.status='paid'
8. ✅ v_current_shift: revenue_total по orders (быстрый preview)
9. ✅ get_hourly_revenue: по orders (для графика нагрузки)

ПРИМЕЧАНИЕ ПО МЕТОДОЛОГИИ ВЫРУЧКИ:
- get_shift_summary: payments.status='paid' (финансовая отчётность)
- get_hourly_revenue: orders.final_amount (оперативная аналитика)
- v_current_shift.revenue_total: orders.final_amount (быстрый preview)

Различие обусловлено:
- payments — точные данные по фактическим оплатам (для закрытия смены)
- orders — быстрые данные для оперативных дашбордов (pending тоже видны)

================================================================================
*/
```
apps-fileview.texmex_20260501.02_p0
ядро 7 этап.txt
ядро 7 этап.txt. На экране.