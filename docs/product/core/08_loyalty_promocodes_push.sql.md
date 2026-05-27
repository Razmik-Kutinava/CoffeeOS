
```sql
-- ============================================================================
-- SQL МИГРАЦИИ ДЛЯ СИСТЕМЫ КОФЕЕН (POSTGRESQL)
-- ЭТАП 9: ЛОЯЛЬНОСТЬ + ПРОМОКОДЫ + PUSH (LOYALTY + PROMO + PUSH)
-- Версия 1.1 - Исправлены пер_customer_limit проверка и лишние индексы
-- ============================================================================

-- ============================================================================
-- ЧАСТЬ A: ТАБЛИЦА loyalty_accounts
-- ============================================================================

CREATE TABLE IF NOT EXISTS loyalty_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL UNIQUE REFERENCES mobile_customers(id) ON DELETE CASCADE,
    balance INTEGER NOT NULL DEFAULT 0,
    lifetime_earned INTEGER NOT NULL DEFAULT 0,
    lifetime_spent INTEGER NOT NULL DEFAULT 0,
    level VARCHAR(50) NOT NULL DEFAULT 'bronze',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_loyalty_balance CHECK (balance >= 0),
    CONSTRAINT chk_loyalty_lifetime_earned CHECK (lifetime_earned >= 0),
    CONSTRAINT chk_loyalty_lifetime_spent CHECK (lifetime_spent >= 0),
    CONSTRAINT chk_loyalty_level CHECK (level IN ('bronze', 'silver', 'gold', 'platinum'))
);

COMMENT ON TABLE loyalty_accounts IS 'Счёт лояльности клиента (глобальная таблица, не привязана к тенанту)';
COMMENT ON COLUMN loyalty_accounts.id IS 'Уникальный идентификатор счёта';
COMMENT ON COLUMN loyalty_accounts.customer_id IS 'Клиент';
COMMENT ON COLUMN loyalty_accounts.balance IS 'Текущий баланс баллов';
COMMENT ON COLUMN loyalty_accounts.lifetime_earned IS 'Всего заработано за всё время';
COMMENT ON COLUMN loyalty_accounts.lifetime_spent IS 'Всего потрачено за всё время';
COMMENT ON COLUMN loyalty_accounts.level IS 'Уровень лояльности: bronze, silver, gold, platinum';
COMMENT ON COLUMN loyalty_accounts.created_at IS 'Дата создания счёта';
COMMENT ON COLUMN loyalty_accounts.updated_at IS 'Дата обновления счёта';

CREATE INDEX idx_loyalty_accounts_customer ON loyalty_accounts(customer_id);
CREATE INDEX idx_loyalty_accounts_level ON loyalty_accounts(level);

CREATE TRIGGER trg_loyalty_accounts_updated_at
    BEFORE UPDATE ON loyalty_accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ЧАСТЬ B: ТАБЛИЦА loyalty_transactions
-- ============================================================================

CREATE TABLE IF NOT EXISTS loyalty_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES mobile_customers(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    tenant_id UUID REFERENCES tenants(id) ON DELETE SET NULL,
    transaction_type VARCHAR(50) NOT NULL,
    points INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    description TEXT,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_transaction_type CHECK (transaction_type IN ('earn', 'spend', 'expire', 'manual_add', 'manual_subtract')),
    CONSTRAINT chk_transaction_points CHECK (points > 0),
    CONSTRAINT chk_transaction_balance_after CHECK (balance_after >= 0)
);

COMMENT ON TABLE loyalty_transactions IS 'История начислений и списаний баллов лояльности';
COMMENT ON COLUMN loyalty_transactions.id IS 'Уникальный идентификатор транзакции';
COMMENT ON COLUMN loyalty_transactions.customer_id IS 'Клиент';
COMMENT ON COLUMN loyalty_transactions.order_id IS 'Заказ (если транзакция связана с заказом)';
COMMENT ON COLUMN loyalty_transactions.tenant_id IS 'Точка, где произошла транзакция';
COMMENT ON COLUMN loyalty_transactions.transaction_type IS 'Тип: earn, spend, expire, manual_add, manual_subtract';
COMMENT ON COLUMN loyalty_transactions.points IS 'Сумма изменения (всегда положительная)';
COMMENT ON COLUMN loyalty_transactions.balance_after IS 'Баланс после транзакции';
COMMENT ON COLUMN loyalty_transactions.description IS 'Описание операции';
COMMENT ON COLUMN loyalty_transactions.created_by IS 'Пользователь создавший транзакцию (для ручных операций)';
COMMENT ON COLUMN loyalty_transactions.created_at IS 'Время создания транзакции';

CREATE INDEX idx_loyalty_transactions_customer_created ON loyalty_transactions(customer_id, created_at DESC);
CREATE INDEX idx_loyalty_transactions_order ON loyalty_transactions(order_id);
CREATE INDEX idx_loyalty_transactions_tenant ON loyalty_transactions(tenant_id);
CREATE INDEX idx_loyalty_transactions_type ON loyalty_transactions(transaction_type);

-- ============================================================================
-- ЧАСТЬ C: ТАБЛИЦА promo_codes
-- ============================================================================

CREATE TABLE IF NOT EXISTS promo_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL UNIQUE,
    discount_type VARCHAR(50) NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    min_order_amount DECIMAL(10,2) DEFAULT 0,
    max_discount_amount DECIMAL(10,2),
    usage_limit INTEGER,
    usage_count INTEGER NOT NULL DEFAULT 0,
    per_customer_limit INTEGER DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_promo_discount_type CHECK (discount_type IN ('percent', 'fixed')),
    CONSTRAINT chk_promo_discount_value CHECK (discount_value > 0),
    CONSTRAINT chk_promo_percent_value CHECK (discount_type = 'fixed' OR discount_value <= 100),
    CONSTRAINT chk_promo_usage_count CHECK (usage_count >= 0),
    CONSTRAINT chk_promo_usage_limit CHECK (usage_limit IS NULL OR usage_count <= usage_limit)
);

COMMENT ON TABLE promo_codes IS 'Промокоды со скидками (привязаны к тенанту или глобальные)';
COMMENT ON COLUMN promo_codes.id IS 'Уникальный идентификатор промокода';
COMMENT ON COLUMN promo_codes.tenant_id IS 'Тенант (NULL = для всей сети)';
COMMENT ON COLUMN promo_codes.code IS 'Код промокода (например COFFEE20)';
COMMENT ON COLUMN promo_codes.discount_type IS 'Тип скидки: percent, fixed';
COMMENT ON COLUMN promo_codes.discount_value IS 'Процент (0-100) или фиксированная сумма';
COMMENT ON COLUMN promo_codes.min_order_amount IS 'Минимальная сумма заказа';
COMMENT ON COLUMN promo_codes.max_discount_amount IS 'Максимальная скидка (для percent типа)';
COMMENT ON COLUMN promo_codes.usage_limit IS 'Максимальное количество использований (NULL = безлимит)';
COMMENT ON COLUMN promo_codes.usage_count IS 'Сколько раз использован';
COMMENT ON COLUMN promo_codes.per_customer_limit IS 'Сколько раз один клиент может использовать';
COMMENT ON COLUMN promo_codes.is_active IS 'Активность промокода';
COMMENT ON COLUMN promo_codes.valid_from IS 'Начало действия';
COMMENT ON COLUMN promo_codes.valid_until IS 'Окончание действия (NULL = бессрочный)';
COMMENT ON COLUMN promo_codes.created_by IS 'Пользователь создавший промокод';
COMMENT ON COLUMN promo_codes.created_at IS 'Дата создания';
COMMENT ON COLUMN promo_codes.updated_at IS 'Дата обновления';

CREATE INDEX idx_promo_codes_code ON promo_codes(code);
CREATE INDEX idx_promo_codes_tenant_active ON promo_codes(tenant_id, is_active);
CREATE INDEX idx_promo_codes_valid ON promo_codes(valid_from, valid_until);
CREATE INDEX idx_promo_codes_active ON promo_codes(is_active);

CREATE TRIGGER trg_promo_codes_updated_at
    BEFORE UPDATE ON promo_codes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ЧАСТЬ D: ТАБЛИЦА promo_code_usages
-- ============================================================================

CREATE TABLE IF NOT EXISTS promo_code_usages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    promo_code_id UUID NOT NULL REFERENCES promo_codes(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES mobile_customers(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    discount_applied DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(promo_code_id, order_id)
);

COMMENT ON TABLE promo_code_usages IS 'История использования промокодов клиентами';
COMMENT ON COLUMN promo_code_usages.id IS 'Уникальный идентификатор использования';
COMMENT ON COLUMN promo_code_usages.promo_code_id IS 'Промокод';
COMMENT ON COLUMN promo_code_usages.customer_id IS 'Клиент';
COMMENT ON COLUMN promo_code_usages.order_id IS 'Заказ';
COMMENT ON COLUMN promo_code_usages.discount_applied IS 'Реальная скидка применённая к заказу';
COMMENT ON COLUMN promo_code_usages.created_at IS 'Время использования';

CREATE INDEX idx_promo_usages_promo ON promo_code_usages(promo_code_id);
CREATE INDEX idx_promo_usages_customer ON promo_code_usages(customer_id);
CREATE INDEX idx_promo_usages_order ON promo_code_usages(order_id);

-- ============================================================================
-- ЧАСТЬ E: ТАБЛИЦА push_notifications
-- ============================================================================

CREATE TABLE IF NOT EXISTS push_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES mobile_customers(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    error_message TEXT,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_push_status CHECK (status IN ('pending', 'sent', 'failed', 'skipped'))
);

COMMENT ON TABLE push_notifications IS 'Очередь и история push-уведомлений';
COMMENT ON COLUMN push_notifications.id IS 'Уникальный идентификатор уведомления';
COMMENT ON COLUMN push_notifications.customer_id IS 'Клиент';
COMMENT ON COLUMN push_notifications.title IS 'Заголовок уведомления';
COMMENT ON COLUMN push_notifications.body IS 'Текст уведомления';
COMMENT ON COLUMN push_notifications.data IS 'Дополнительные данные (order_id, promo_code и т.д.)';
COMMENT ON COLUMN push_notifications.status IS 'Статус: pending, sent, failed, skipped';
COMMENT ON COLUMN push_notifications.error_message IS 'Сообщение об ошибке при отправке';
COMMENT ON COLUMN push_notifications.sent_at IS 'Время отправки';
COMMENT ON COLUMN push_notifications.created_at IS 'Время создания';

CREATE INDEX idx_push_notifications_customer ON push_notifications(customer_id);
CREATE INDEX idx_push_notifications_status_created ON push_notifications(status, created_at);
CREATE INDEX idx_push_notifications_pending ON push_notifications(created_at) WHERE status = 'pending';

-- ============================================================================
-- ЧАСТЬ F: РАСШИРЕНИЕ ТАБЛИЦЫ orders
-- ============================================================================

ALTER TABLE orders 
    ADD COLUMN IF NOT EXISTS promo_code_id UUID REFERENCES promo_codes(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS loyalty_points_earned INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS loyalty_points_spent INTEGER DEFAULT 0;

COMMENT ON COLUMN orders.promo_code_id IS 'Промокод применённый к заказу';
COMMENT ON COLUMN orders.loyalty_points_earned IS 'Начислено баллов за заказ';
COMMENT ON COLUMN orders.loyalty_points_spent IS 'Списано баллов при оплате';

-- ИСПРАВЛЕНИЕ #2: Убраны лишние индексы на loyalty_points_earned/spent
-- (низкая селективность, дефолт 0, планировщик не использует)
CREATE INDEX IF NOT EXISTS idx_orders_promo_code ON orders(promo_code_id);

-- ============================================================================
-- ЧАСТЬ G: ФУНКЦИИ ЛОЯЛЬНОСТИ
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: get_or_create_loyalty_account
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_or_create_loyalty_account(
    p_customer_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_account_id UUID;
BEGIN
    -- Upsert счёта лояльности
    INSERT INTO loyalty_accounts (customer_id)
    VALUES (p_customer_id)
    ON CONFLICT (customer_id) DO UPDATE
    SET updated_at = NOW()
    RETURNING id INTO v_account_id;
    
    RETURN v_account_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: earn_loyalty_points
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION earn_loyalty_points(
    p_customer_id UUID,
    p_order_id UUID,
    p_tenant_id UUID,
    p_order_amount DECIMAL(10,2)
)
RETURNS INTEGER AS $$
DECLARE
    v_account RECORD;
    v_points INTEGER;
    v_new_level VARCHAR(50);
BEGIN
    -- Считаем баллы: 1 балл за каждые 100 рублей
    v_points := FLOOR(p_order_amount / 100)::INTEGER;
    
    -- Если баллов нет — ничего не делаем
    IF v_points = 0 THEN
        RETURN 0;
    END IF;
    
    -- Блокируем счёт лояльности
    SELECT * INTO v_account
    FROM loyalty_accounts
    WHERE customer_id = p_customer_id
    FOR UPDATE;
    
    -- Если счёта нет — создаём
    IF NOT FOUND THEN
        PERFORM get_or_create_loyalty_account(p_customer_id);
        
        SELECT * INTO v_account
        FROM loyalty_accounts
        WHERE customer_id = p_customer_id
        FOR UPDATE;
    END IF;
    
    -- Определяем новый уровень
    v_new_level := CASE 
        WHEN v_account.lifetime_earned + v_points >= 5000 THEN 'platinum'
        WHEN v_account.lifetime_earned + v_points >= 2000 THEN 'gold'
        WHEN v_account.lifetime_earned + v_points >= 500 THEN 'silver'
        ELSE 'bronze'
    END;
    
    -- Обновляем счёт
    UPDATE loyalty_accounts
    SET balance = balance + v_points,
        lifetime_earned = lifetime_earned + v_points,
        level = v_new_level,
        updated_at = NOW()
    WHERE customer_id = p_customer_id;
    
    -- Записываем транзакцию
    INSERT INTO loyalty_transactions (
        customer_id, order_id, tenant_id, transaction_type,
        points, balance_after, description
    ) VALUES (
        p_customer_id, p_order_id, p_tenant_id, 'earn',
        v_points, v_account.balance + v_points,
        'Начисление за заказ #' || (SELECT order_number FROM orders WHERE id = p_order_id)
    );
    
    -- Обновляем заказ
    UPDATE orders
    SET loyalty_points_earned = v_points
    WHERE id = p_order_id;
    
    RETURN v_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: spend_loyalty_points
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION spend_loyalty_points(
    p_customer_id UUID,
    p_order_id UUID,
    p_tenant_id UUID,
    p_points INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_account RECORD;
BEGIN
    -- Проверяем что points > 0
    IF p_points <= 0 THEN
        RAISE EXCEPTION 'Количество баллов должно быть положительным';
    END IF;
    
    -- Блокируем счёт лояльности
    SELECT * INTO v_account
    FROM loyalty_accounts
    WHERE customer_id = p_customer_id
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Счёт лояльности не найден';
    END IF;
    
    -- Проверяем баланс
    IF v_account.balance < p_points THEN
        RAISE EXCEPTION 'Недостаточно баллов (доступно: %, требуется: %)', v_account.balance, p_points;
    END IF;
    
    -- Обновляем счёт
    UPDATE loyalty_accounts
    SET balance = balance - p_points,
        lifetime_spent = lifetime_spent + p_points,
        updated_at = NOW()
    WHERE customer_id = p_customer_id;
    
    -- Записываем транзакцию
    INSERT INTO loyalty_transactions (
        customer_id, order_id, tenant_id, transaction_type,
        points, balance_after, description
    ) VALUES (
        p_customer_id, p_order_id, p_tenant_id, 'spend',
        p_points, v_account.balance - p_points,
        'Списание за заказ #' || (SELECT order_number FROM orders WHERE id = p_order_id)
    );
    
    -- Обновляем заказ
    UPDATE orders
    SET loyalty_points_spent = p_points
    WHERE id = p_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: manual_adjust_loyalty
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION manual_adjust_loyalty(
    p_customer_id UUID,
    p_points INTEGER,
    p_transaction_type VARCHAR,
    p_description TEXT,
    p_created_by UUID
)
RETURNS VOID AS $$
DECLARE
    v_account RECORD;
BEGIN
    -- Проверяем тип транзакции
    IF p_transaction_type NOT IN ('manual_add', 'manual_subtract') THEN
        RAISE EXCEPTION 'Неверный тип транзакции: %', p_transaction_type;
    END IF;
    
    -- Блокируем счёт лояльности
    SELECT * INTO v_account
    FROM loyalty_accounts
    WHERE customer_id = p_customer_id
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Счёт лояльности не найден';
    END IF;
    
    -- Для списания проверяем баланс
    IF p_transaction_type = 'manual_subtract' AND v_account.balance < p_points THEN
        RAISE EXCEPTION 'Недостаточно баллов для списания';
    END IF;
    
    -- Обновляем счёт
    IF p_transaction_type = 'manual_add' THEN
        UPDATE loyalty_accounts
        SET balance = balance + p_points,
            lifetime_earned = lifetime_earned + p_points,
            updated_at = NOW()
        WHERE customer_id = p_customer_id;
    ELSE
        UPDATE loyalty_accounts
        SET balance = balance - p_points,
            lifetime_spent = lifetime_spent + p_points,
            updated_at = NOW()
        WHERE customer_id = p_customer_id;
    END IF;
    
    -- Записываем транзакцию
    INSERT INTO loyalty_transactions (
        customer_id, transaction_type, points, balance_after,
        description, created_by
    ) VALUES (
        p_customer_id, p_transaction_type, p_points,
        CASE WHEN p_transaction_type = 'manual_add' 
             THEN v_account.balance + p_points 
             ELSE v_account.balance - p_points END,
        p_description, p_created_by
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ЧАСТЬ H: ФУНКЦИИ ПРОМОКОДОВ
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: validate_promo_code
-- ИСПРАВЛЕНИЕ #1: per_customer_limit IS NOT NULL проверка
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION validate_promo_code(
    p_code VARCHAR,
    p_tenant_id UUID,
    p_customer_id UUID,
    p_order_amount DECIMAL(10,2)
)
RETURNS TABLE (
    promo_code_id UUID,
    discount_type VARCHAR(50),
    discount_value DECIMAL(10,2),
    discount_amount DECIMAL(10,2)
) AS $$
DECLARE
    v_promo RECORD;
    v_usage_count INTEGER;
    v_discount_amount DECIMAL(10,2);
BEGIN
    -- Находим промокод
    SELECT * INTO v_promo
    FROM promo_codes
    WHERE code = p_code
      AND is_active = TRUE
      AND valid_from <= NOW()
      AND (valid_until IS NULL OR valid_until >= NOW())
      AND (tenant_id = p_tenant_id OR tenant_id IS NULL);
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Промокод не найден или недействителен';
    END IF;
    
    -- Проверяем usage_limit
    IF v_promo.usage_limit IS NOT NULL AND v_promo.usage_count >= v_promo.usage_limit THEN
        RAISE EXCEPTION 'Промокод исчерпан';
    END IF;
    
    -- Проверяем min_order_amount
    IF p_order_amount < v_promo.min_order_amount THEN
        RAISE EXCEPTION 'Сумма заказа меньше минимальной (требуется: %)', v_promo.min_order_amount;
    END IF;
    
    -- Проверяем per_customer_limit
    -- ИСПРАВЛЕНИЕ #1: Добавлена проверка IS NOT NULL
    SELECT COUNT(*) INTO v_usage_count
    FROM promo_code_usages
    WHERE promo_code_id = v_promo.id
      AND customer_id = p_customer_id;
    
    IF v_promo.per_customer_limit IS NOT NULL 
       AND v_usage_count >= v_promo.per_customer_limit THEN
        RAISE EXCEPTION 'Вы уже использовали этот промокод';
    END IF;
    
    -- Считаем discount_amount
    IF v_promo.discount_type = 'percent' THEN
        v_discount_amount := p_order_amount * v_promo.discount_value / 100;
        IF v_promo.max_discount_amount IS NOT NULL THEN
            v_discount_amount := LEAST(v_discount_amount, v_promo.max_discount_amount);
        END IF;
    ELSE
        v_discount_amount := v_promo.discount_value;
    END IF;
    
    -- Скидка не может превышать сумму заказа
    v_discount_amount := LEAST(v_discount_amount, p_order_amount);
    
    promo_code_id := v_promo.id;
    discount_type := v_promo.discount_type;
    discount_value := v_promo.discount_value;
    discount_amount := v_discount_amount;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: apply_promo_code
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION apply_promo_code(
    p_order_id UUID,
    p_promo_code_id UUID,
    p_customer_id UUID,
    p_discount_amount DECIMAL(10,2)
)
RETURNS VOID AS $$
DECLARE
    v_order RECORD;
BEGIN
    -- Блокируем заказ
    SELECT * INTO v_order
    FROM orders
    WHERE id = p_order_id
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заказ не найден';
    END IF;
    
    -- Обновляем заказ
    UPDATE orders
    SET discount_amount = p_discount_amount,
        final_amount = total_amount - p_discount_amount,
        promo_code_id = p_promo_code_id,
        updated_at = NOW()
    WHERE id = p_order_id;
    
    -- Увеличиваем счётчик использования промокода
    UPDATE promo_codes
    SET usage_count = usage_count + 1,
        updated_at = NOW()
    WHERE id = p_promo_code_id;
    
    -- Записываем использование
    INSERT INTO promo_code_usages (promo_code_id, customer_id, order_id, discount_applied)
    VALUES (p_promo_code_id, p_customer_id, p_order_id, p_discount_amount);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ЧАСТЬ I: ФУНКЦИИ PUSH-УВЕДОМЛЕНИЙ
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: queue_push_notification
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION queue_push_notification(
    p_customer_id UUID,
    p_title VARCHAR(255),
    p_body TEXT,
    p_data JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
    v_push_enabled BOOLEAN;
BEGIN
    -- Проверяем push_enabled у клиента
    SELECT push_enabled INTO v_push_enabled
    FROM mobile_customers
    WHERE id = p_customer_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Клиент не найден';
    END IF;
    
    -- Если push отключен — создаём со status='skipped'
    IF v_push_enabled = FALSE THEN
        INSERT INTO push_notifications (customer_id, title, body, data, status)
        VALUES (p_customer_id, p_title, p_body, p_data, 'skipped')
        RETURNING id INTO v_notification_id;
    ELSE
        -- Создаём pending уведомление
        INSERT INTO push_notifications (customer_id, title, body, data, status)
        VALUES (p_customer_id, p_title, p_body, p_data, 'pending')
        RETURNING id INTO v_notification_id;
    END IF;
    
    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: mark_push_sent
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION mark_push_sent(
    p_notification_id UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE push_notifications
    SET status = 'sent',
        sent_at = NOW()
    WHERE id = p_notification_id
      AND status = 'pending';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: mark_push_failed
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION mark_push_failed(
    p_notification_id UUID,
    p_error_message TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE push_notifications
    SET status = 'failed',
        error_message = p_error_message
    WHERE id = p_notification_id
      AND status = 'pending';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: get_pending_push_notifications
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_pending_push_notifications(
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
    notification_id UUID,
    customer_id UUID,
    push_token TEXT,
    title VARCHAR(255),
    body TEXT,
    data JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pn.id AS notification_id,
        pn.customer_id,
        mc.push_token,
        pn.title,
        pn.body,
        pn.data
    FROM push_notifications pn
    JOIN mobile_customers mc ON pn.customer_id = mc.id
    WHERE pn.status = 'pending'
      AND mc.push_token IS NOT NULL
      AND mc.push_enabled = TRUE
    ORDER BY pn.created_at ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- ЧАСТЬ J: VIEWS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- VIEW: v_customer_loyalty
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_customer_loyalty AS
SELECT 
    mc.id AS customer_id,
    mc.phone,
    mc.first_name,
    mc.last_name,
    la.id AS loyalty_account_id,
    la.balance,
    la.lifetime_earned,
    la.lifetime_spent,
    la.level,
    CASE 
        WHEN la.level = 'platinum' THEN 'max'
        WHEN la.level = 'gold' THEN 'platinum'
        WHEN la.level = 'silver' THEN 'gold'
        WHEN la.level = 'bronze' THEN 'silver'
    END AS next_level,
    CASE 
        WHEN la.level = 'platinum' THEN 0
        WHEN la.level = 'gold' THEN 5000 - la.lifetime_earned
        WHEN la.level = 'silver' THEN 2000 - la.lifetime_earned
        WHEN la.level = 'bronze' THEN 500 - la.lifetime_earned
    END AS points_to_next_level
FROM mobile_customers mc
LEFT JOIN loyalty_accounts la ON mc.id = la.customer_id
WHERE mc.is_active = TRUE;

COMMENT ON VIEW v_customer_loyalty IS 'Полная информация о программе лояльности клиента';

-- ----------------------------------------------------------------------------
-- VIEW: v_active_promo_codes
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_active_promo_codes AS
SELECT 
    id,
    tenant_id,
    code,
    discount_type,
    discount_value,
    min_order_amount,
    max_discount_amount,
    usage_limit,
    usage_count,
    per_customer_limit,
    valid_from,
    valid_until,
    CASE 
        WHEN usage_limit IS NULL THEN NULL
        ELSE usage_limit - usage_count
    END AS uses_remaining
FROM promo_codes
WHERE is_active = TRUE
  AND (valid_until IS NULL OR valid_until >= NOW());

COMMENT ON VIEW v_active_promo_codes IS 'Активные промокоды (is_active=TRUE, не истёкшие)';

-- ============================================================================
-- ЧАСТЬ K: ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE loyalty_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_code_usages ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notifications ENABLE ROW LEVEL SECURITY;

-- loyalty_accounts: read — свой account или office_manager/УК
CREATE POLICY rls_loyalty_accounts_read ON loyalty_accounts
    FOR SELECT
    USING (
        customer_id = NULLIF(current_setting('app.current_customer_id', TRUE), '')::UUID
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('office_manager', 'ук_global_admin', 'ук_country_manager', 'ук_billing_admin')
        )
    );

-- loyalty_accounts: write — только через SECURITY DEFINER функции (нет policy для INSERT/UPDATE/DELETE)

-- loyalty_transactions: read — свои транзакции или office_manager/УК
CREATE POLICY rls_loyalty_transactions_read ON loyalty_transactions
    FOR SELECT
    USING (
        customer_id = NULLIF(current_setting('app.current_customer_id', TRUE), '')::UUID
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('office_manager', 'ук_global_admin', 'ук_country_manager', 'ук_billing_admin')
        )
    );

-- promo_codes: read — все авторизованные
CREATE POLICY rls_promo_codes_read ON promo_codes
    FOR SELECT
    USING (TRUE);

-- promo_codes: write — office_manager/УК
CREATE POLICY rls_promo_codes_write ON promo_codes
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('office_manager', 'ук_global_admin', 'ук_country_manager')
        )
    );

-- promo_code_usages: read — своё или office_manager/УК
CREATE POLICY rls_promo_usages_read ON promo_code_usages
    FOR SELECT
    USING (
        customer_id = NULLIF(current_setting('app.current_customer_id', TRUE), '')::UUID
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('office_manager', 'ук_global_admin', 'ук_country_manager')
        )
    );

-- push_notifications: read — своё или ук_global_admin
CREATE POLICY rls_push_notifications_read ON push_notifications
    FOR SELECT
    USING (
        customer_id = NULLIF(current_setting('app.current_customer_id', TRUE), '')::UUID
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager')
        )
    );

-- ============================================================================
-- ЧАСТЬ L: SEED DATA
-- ============================================================================

BEGIN;

SET LOCAL row_security = off;

-- 1. Создаём loyalty_account для тестового клиента
INSERT INTO loyalty_accounts (customer_id, balance, lifetime_earned, lifetime_spent, level)
SELECT 
    mc.id,
    150,
    150,
    0,
    'bronze'
FROM mobile_customers mc
WHERE mc.phone = '+79000000001'
ON CONFLICT (customer_id) DO UPDATE SET
    balance = 150,
    lifetime_earned = 150,
    lifetime_spent = 0,
    level = 'bronze',
    updated_at = NOW();

-- 2. Создаём тестовый промокод 'WELCOME10' (для всей сети)
INSERT INTO promo_codes (
    tenant_id, code, discount_type, discount_value,
    min_order_amount, per_customer_limit, is_active,
    valid_from, valid_until, created_by
) VALUES (
    NULL,
    'WELCOME10',
    'percent',
    10,
    200,
    1,
    TRUE,
    NOW(),
    NOW() + INTERVAL '30 days',
    NULL
)
ON CONFLICT (code) DO UPDATE SET
    discount_type = EXCLUDED.discount_type,
    discount_value = EXCLUDED.discount_value,
    min_order_amount = EXCLUDED.min_order_amount,
    per_customer_limit = EXCLUDED.per_customer_limit,
    is_active = EXCLUDED.is_active,
    valid_until = EXCLUDED.valid_until,
    updated_at = NOW();

-- 3. Создаём тестовый промокод 'FLAT50' (для тестового тенанта)
INSERT INTO promo_codes (
    tenant_id, code, discount_type, discount_value,
    min_order_amount, per_customer_limit, is_active,
    valid_from, valid_until, created_by
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'FLAT50',
    'fixed',
    50,
    300,
    3,
    TRUE,
    NOW(),
    NOW() + INTERVAL '60 days',
    NULL
)
ON CONFLICT (code) DO UPDATE SET
    discount_type = EXCLUDED.discount_type,
    discount_value = EXCLUDED.discount_value,
    min_order_amount = EXCLUDED.min_order_amount,
    per_customer_limit = EXCLUDED.per_customer_limit,
    is_active = EXCLUDED.is_active,
    valid_until = EXCLUDED.valid_until,
    updated_at = NOW();

COMMIT;

-- ============================================================================
-- КОНЕЦ МИГРАЦИЙ ЭТАПА 9
-- ============================================================================

/*
================================================================================
ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ

1. КАК ПОЛУЧИТЬ ИЛИ СОЗДАТЬ СЧЁТ ЛОЯЛЬНОСТИ
   SELECT get_or_create_loyalty_account('customer-uuid');

2. КАК НАЧИСЛИТЬ БАЛЛЫ ЗА ЗАКАЗ
   SELECT earn_loyalty_points('customer-uuid', 'order-uuid', 'tenant-uuid', 450.00);
   -- Начислит 4 балла (450 / 100 = 4.5 → FLOOR = 4)

3. КАК СПИСАТЬ БАЛЛЫ
   SELECT spend_loyalty_points('customer-uuid', 'order-uuid', 'tenant-uuid', 100);

4. КАК РУЧНО СКОРРЕКТИРОВАТЬ БАЛАНС
   SELECT manual_adjust_loyalty('customer-uuid', 50, 'manual_add', 'Подарок', 'user-uuid');

5. КАК ПРОВЕРИТЬ ПРОМОКОД
   SELECT * FROM validate_promo_code('WELCOME10', 'tenant-uuid', 'customer-uuid', 350.00);

6. КАК ПРИМЕНИТЬ ПРОМОКОД К ЗАКАЗУ
   SELECT apply_promo_code('order-uuid', 'promo-code-uuid', 'customer-uuid', 35.00);

7. КАК ДОБАВИТЬ PUSH-УВЕДОМЛЕНИЕ В ОЧЕРЕДЬ
   SELECT queue_push_notification('customer-uuid', 'Заказ готов!', 'Заказ #0042 готов к выдаче');

8. КАК ПОЛУЧИТЬ ОЧЕРЕДЬ PENDING УВЕДОМЛЕНИЙ
   SELECT * FROM get_pending_push_notifications(100);

================================================================================
ИСПРАВЛЕНИЯ В ЭТОЙ ВЕРСИИ (1.1)

1. ✅ validate_promo_code: per_customer_limit IS NOT NULL проверка
   - Было: IF v_usage_count >= v_promo.per_customer_limit THEN
   - Стало: IF v_promo.per_customer_limit IS NOT NULL AND v_usage_count >= ...
   - Если per_customer_limit = NULL (безлимит для клиента) — проверка пропускается

2. ✅ Убраны лишние индексы на orders.loyalty_points_earned/spent
   - Колонки имеют дефолт 0 и низкую селективность
   - Планировщик PostgreSQL не использует такие индексы
   - Оставлен только idx_orders_promo_code

================================================================================
АРХИТЕКТУРНЫЕ ЗАМЕЧАНИЯ

1. ✅ loyalty_accounts — глобальная таблица (один счёт на клиента)
2. ✅ Начисление: 1 балл за 100 рублей (FLOOR), early return при 0
3. ✅ Уровни: bronze (<500) → silver (500-2000) → gold (2000-5000) → platinum (>=5000)
4. ✅ Глобальные промокоды (tenant_id IS NULL) работают везде
5. ✅ per_customer_limit: NULL = безлимит для клиента
6. ✅ Push-очередь: pending → sent/failed/skipped
7. ✅ INTEGER для баллов, DECIMAL(10,2) для денег
8. ✅ FOR UPDATE в earn/spend/manual_adjust/apply_promo_code
9. ✅ RLS на loyalty_accounts без write policy (только функции)
10. ✅ v_customer_loyalty: next_level и points_to_next_level

================================================================================
*/
```
apps-fileview.texmex_20260501.02_p0
ядро 9 этап.txt
ядро 9 этап.txt. На экране.