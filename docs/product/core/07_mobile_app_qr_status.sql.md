
-- ============================================================================
-- SQL МИГРАЦИИ ДЛЯ СИСТЕМЫ КОФЕЕН (POSTGRESQL)
-- ЭТАП 8: МОБИЛЬНОЕ APP + QR-СТАТУС
-- Версия 2.1 — Финальная. Синхронизировано с CODE BLACK flow v3.0
-- ============================================================================
-- ИЗМЕНЕНИЯ v2.1 vs v2.0 (по gap-анализу CODE BLACK v3.0):
--   [A] mobile_customers: + preferred_tenant_id — выбранная точка
--   [B] mobile_customers: push_enabled BOOLEAN → push_consent_status ENUM
--       ('granted'|'denied'|'ask_again') — три состояния согласия
--   [C] mobile_customers: + onboarding_completed_at — после 2 заказов
--       подсказки больше не показываем
--   [D] order_feedback: + positive_tags TEXT[] — шаг «Что нравится?»
--       Решение по ОС: ОДИН квиз на весь заказ, не по позициям
--   [E] orders: tips_payment_id → tips_initiated_at — чаевые это
--       редирект в НЕТМОНЕТ, внутренний payment не нужен
--   [F] payments CHECK: убран 'apple_pay' (рынок РФ, v3.0)
--   [G] get_last_orders_for_ghost_bar: история 32 заказа (v3.0)
-- ============================================================================


-- ============================================================================
-- ЧАСТЬ A: ТАБЛИЦА mobile_customers
-- ============================================================================

CREATE TABLE IF NOT EXISTS mobile_customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    birth_date DATE,
    push_token TEXT,

    -- [B] Три состояния согласия на push:
    --   'granted'    — разрешил → отправляем уведомления
    --   'denied'     — запретил → не отправляем никогда
    --   'ask_again'  — "Только в этот раз" → спросим при следующем входе
    push_consent_status VARCHAR(20) NOT NULL DEFAULT 'ask_again',

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMP WITH TIME ZONE,

    -- [A] Выбранная точка — сохраняется при авто/ручном выборе
    -- При смене точки — перезаписывается
    preferred_tenant_id UUID REFERENCES tenants(id) ON DELETE SET NULL,

    -- [C] Онбординг: подсказки показываем только первые 2 заказа
    -- NULL = онбординг ещё не завершён (не набрал 2 выполненных заказа)
    onboarding_completed_at TIMESTAMP WITH TIME ZONE,

    -- [4 v2.0] Геолокация — кешируется, подставляется при следующем входе
    city VARCHAR(100),
    geo_lat DECIMAL(10,6),
    geo_lon DECIMAL(10,6),
    geo_updated_at TIMESTAMP WITH TIME ZONE,

    -- [7 v2.0] Rate-limit OTP
    otp_send_count INTEGER NOT NULL DEFAULT 0,
    otp_last_sent_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_mobile_phone_format CHECK (
        phone ~ '^[+]?[0-9]{10,15}$'
    ),
    CONSTRAINT chk_push_consent CHECK (
        push_consent_status IN ('granted', 'denied', 'ask_again')
    )
);

COMMENT ON TABLE mobile_customers IS 'Клиенты мобильного приложения (глобальная таблица, не привязана к тенанту)';
COMMENT ON COLUMN mobile_customers.id IS 'Уникальный идентификатор клиента';
COMMENT ON COLUMN mobile_customers.phone IS 'Номер телефона — основной идентификатор';
COMMENT ON COLUMN mobile_customers.email IS 'Email адрес (для чека, опционально)';
COMMENT ON COLUMN mobile_customers.first_name IS 'Имя';
COMMENT ON COLUMN mobile_customers.last_name IS 'Фамилия';
COMMENT ON COLUMN mobile_customers.birth_date IS 'Дата рождения';
COMMENT ON COLUMN mobile_customers.push_token IS 'FCM/APNs токен для push-уведомлений';
COMMENT ON COLUMN mobile_customers.push_consent_status IS '[B] Согласие на push: granted=разрешил | denied=запретил | ask_again=только в этот раз (спросить снова при следующем входе)';
COMMENT ON COLUMN mobile_customers.is_active IS 'Активность учётной записи';
COMMENT ON COLUMN mobile_customers.last_login_at IS 'Последний вход';
COMMENT ON COLUMN mobile_customers.preferred_tenant_id IS '[A] Выбранная кофейня — сохраняется при авто/ручном выборе точки, подставляется при следующем входе';
COMMENT ON COLUMN mobile_customers.onboarding_completed_at IS '[C] Когда онбординг завершён (набрал 2 выполненных заказа). NULL = ещё показываем подсказки. Не NULL = подсказки больше не показываем никогда.';
COMMENT ON COLUMN mobile_customers.city IS 'Город из геолокации — кешируется';
COMMENT ON COLUMN mobile_customers.geo_lat IS 'Широта последней геолокации';
COMMENT ON COLUMN mobile_customers.geo_lon IS 'Долгота последней геолокации';
COMMENT ON COLUMN mobile_customers.geo_updated_at IS 'Когда обновлялась геолокация';
COMMENT ON COLUMN mobile_customers.otp_send_count IS 'Счётчик отправок OTP за текущий час (rate-limit)';
COMMENT ON COLUMN mobile_customers.otp_last_sent_at IS 'Время последней отправки OTP';
COMMENT ON COLUMN mobile_customers.created_at IS 'Дата регистрации';
COMMENT ON COLUMN mobile_customers.updated_at IS 'Дата обновления профиля';

CREATE INDEX idx_mobile_customers_phone ON mobile_customers(phone);
CREATE INDEX idx_mobile_customers_email ON mobile_customers(email);
CREATE INDEX idx_mobile_customers_active ON mobile_customers(is_active);
CREATE INDEX idx_mobile_customers_preferred_tenant ON mobile_customers(preferred_tenant_id);
CREATE INDEX idx_mobile_customers_geo ON mobile_customers(geo_lat, geo_lon) WHERE geo_lat IS NOT NULL;
CREATE INDEX idx_mobile_customers_push_ask ON mobile_customers(push_consent_status)
    WHERE push_consent_status = 'ask_again';

CREATE TRIGGER trg_mobile_customers_updated_at
    BEFORE UPDATE ON mobile_customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- ЧАСТЬ B: ТАБЛИЦА mobile_otp_codes
-- ============================================================================

CREATE TABLE IF NOT EXISTS mobile_otp_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) NOT NULL,
    code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() + INTERVAL '5 minutes'),
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    attempts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_otp_attempts CHECK (attempts <= 5),
    CONSTRAINT chk_otp_code_format CHECK (code ~ '^[0-9]{6}$')
);

COMMENT ON TABLE mobile_otp_codes IS 'OTP-коды для авторизации по номеру телефона (без пароля). Макс 5 попыток ввода, TTL 5 минут.';
COMMENT ON COLUMN mobile_otp_codes.code IS '6-значный код подтверждения';
COMMENT ON COLUMN mobile_otp_codes.expires_at IS 'Время истечения кода (5 минут)';
COMMENT ON COLUMN mobile_otp_codes.is_used IS 'Код уже использован';
COMMENT ON COLUMN mobile_otp_codes.attempts IS 'Количество попыток ввода (макс 5 — CHECK constraint)';

CREATE INDEX idx_otp_phone_used_expires ON mobile_otp_codes(phone, is_used, expires_at);
CREATE INDEX idx_otp_created_at ON mobile_otp_codes(created_at);
CREATE INDEX idx_otp_active ON mobile_otp_codes(expires_at) WHERE is_used = FALSE;


-- ============================================================================
-- ЧАСТЬ C: ТАБЛИЦА mobile_sessions
-- ============================================================================

CREATE TABLE IF NOT EXISTS mobile_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES mobile_customers(id) ON DELETE CASCADE,
    refresh_token UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    device_info JSONB,
    ip_address VARCHAR(45),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() + INTERVAL '30 days'),
    last_used_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE mobile_sessions IS 'Сессии авторизованных клиентов. Refresh token ротируется при каждом использовании.';
COMMENT ON COLUMN mobile_sessions.refresh_token IS 'Токен для обновления сессии — ротируется, старый деактивируется';
COMMENT ON COLUMN mobile_sessions.device_info IS 'JSONB: модель, OS, версия app — для аудита';
COMMENT ON COLUMN mobile_sessions.expires_at IS 'TTL 30 дней';

CREATE INDEX idx_mobile_sessions_customer ON mobile_sessions(customer_id);
CREATE INDEX idx_mobile_sessions_token ON mobile_sessions(refresh_token);
CREATE INDEX idx_mobile_sessions_active ON mobile_sessions(customer_id, expires_at)
    WHERE is_active = TRUE;


-- ============================================================================
-- ЧАСТЬ D: ТАБЛИЦА mobile_payment_methods
-- Токены карт и методов оплаты для повторного заказа без чекаута
-- ============================================================================

CREATE TABLE IF NOT EXISTS mobile_payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES mobile_customers(id) ON DELETE CASCADE,
    -- [F] apple_pay убран (рынок РФ). Доступны: card, sbp, ya_pay
    payment_type VARCHAR(20) NOT NULL DEFAULT 'card',
    -- Данные карты (только для type=card)
    card_token TEXT,           -- токен от эквайера (хранить зашифрованным через pgcrypto)
    card_masked VARCHAR(20),   -- **** 1234 — только для отображения пользователю
    card_brand VARCHAR(20),    -- Visa / Mastercard / Mir
    card_expires_at VARCHAR(7), -- MM/YYYY — только для отображения
    -- Управление
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_pm_type CHECK (
        payment_type IN ('card', 'sbp', 'ya_pay')
        -- apple_pay УДАЛЁН: v3.0, рынок РФ
    )
);

COMMENT ON TABLE mobile_payment_methods IS 'Сохранённые методы оплаты. Нужны для «Купить сейчас» в Ghost Bar без открытия чекаута.';
COMMENT ON COLUMN mobile_payment_methods.card_token IS '⚠️ Токен от эквайера. НЕ является номером карты. Хранить зашифрованным (pgcrypto/application-level encryption).';
COMMENT ON COLUMN mobile_payment_methods.card_masked IS 'Маска **** 1234 — показывается пользователю в Ghost Bar и чекауте';
COMMENT ON COLUMN mobile_payment_methods.is_default IS 'Метод по умолчанию для «Купить сейчас»';
COMMENT ON COLUMN mobile_payment_methods.is_active IS 'FALSE = токен отозван банком или пользователь удалил карту';
COMMENT ON COLUMN mobile_payment_methods.last_used_at IS 'Последнее успешное списание — для определения протухшего токена ДО показа кнопки (v3.0)';

CREATE INDEX idx_pm_customer ON mobile_payment_methods(customer_id);
CREATE INDEX idx_pm_default ON mobile_payment_methods(customer_id)
    WHERE is_default = TRUE AND is_active = TRUE;
CREATE INDEX idx_pm_active ON mobile_payment_methods(customer_id, is_active)
    WHERE is_active = TRUE;


-- ============================================================================
-- ЧАСТЬ E: ТАБЛИЦА mobile_carts
-- Ghost Bar — мобильная корзина, TTL 24 часа
-- ============================================================================

CREATE TABLE IF NOT EXISTS mobile_carts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES mobile_customers(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    -- Формат: [{"product_id":"uuid","quantity":2,
    --           "modifier_options":{"milk_type":"opt-uuid"},"price":350.00}]
    items JSONB NOT NULL DEFAULT '[]'::JSONB,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    -- TTL 24 часа. Сбрасывается при каждом изменении.
    -- cleanup_mobile_data() чистит просроченные.
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() + INTERVAL '24 hours'),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    -- Один клиент = одна активная корзина на точку
    UNIQUE(customer_id, tenant_id),
    CONSTRAINT chk_cart_total CHECK (total_amount >= 0)
);

COMMENT ON TABLE mobile_carts IS 'Мобильная корзина клиента (Ghost Bar). Сохраняется между сессиями, TTL 24 часа (CODE BLACK v3.0 п.7).';
COMMENT ON COLUMN mobile_carts.expires_at IS 'TTL 24ч. Если не купили — обнулять при следующем открытии приложения (v3.0).';
COMMENT ON COLUMN mobile_carts.items IS 'JSONB: [{product_id, quantity, modifier_options, price}]. Синхронизируется с каждым изменением состава.';

CREATE INDEX idx_mobile_carts_customer ON mobile_carts(customer_id);
CREATE INDEX idx_mobile_carts_tenant ON mobile_carts(tenant_id);
CREATE INDEX idx_mobile_carts_expires ON mobile_carts(expires_at);

CREATE TRIGGER trg_mobile_carts_updated_at
    BEFORE UPDATE ON mobile_carts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- ЧАСТЬ F: ТАБЛИЦА order_feedback
-- Квиз обратной связи — ОДИН квиз на весь заказ (решение принято)
-- ============================================================================

CREATE TABLE IF NOT EXISTS order_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES mobile_customers(id) ON DELETE CASCADE,

    -- Шаг 1: «Всё хорошо?»
    is_positive BOOLEAN,         -- TRUE=Да / FALSE=Нет / NULL=закрыл без ответа

    -- [D] Шаг 2а (если is_positive=TRUE): «Что нравится?»
    positive_tags TEXT[],        -- ['price','taste','prepared_as_wanted']
    -- Шаг 2б (если is_positive=FALSE): «Что смутило?»
    issue_tags TEXT[],           -- ['price','taste','temperature','speed','portion']
    -- Шаг 3 (если is_positive=FALSE): «Что исправить?»
    improve_tags TEXT[],         -- ['portion','speed','temperature']

    -- Итоговая оценка и комментарий (опционально)
    rating SMALLINT,
    comment TEXT,

    -- ⚠️ РЕШЕНИЕ (CODE BLACK v3.0, вопрос #5):
    -- Один квиз на весь заказ, не по позициям.
    -- Если несколько позиций — клиент оценивает общий опыт.
    -- Обоснование: снижает усталость, индустриальный стандарт (Starbucks, Surf).
    -- Если потребуется per-item — расширять через items_feedback JSONB.
    items_feedback JSONB,        -- зарезервировано для будущего, сейчас NULL

    -- Управление показом квиза
    -- UX-правило: показали и закрыл без ответа → was_shown=TRUE, was_answered=FALSE
    -- → больше не показываем (CODE BLACK v3.0)
    was_shown BOOLEAN NOT NULL DEFAULT FALSE,
    was_answered BOOLEAN NOT NULL DEFAULT FALSE,
    shown_at TIMESTAMP WITH TIME ZONE,
    answered_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_feedback_rating CHECK (rating IS NULL OR rating BETWEEN 1 AND 5),
    CONSTRAINT chk_positive_tags CHECK (
        positive_tags IS NULL OR
        positive_tags <@ ARRAY['price','taste','prepared_as_wanted']::TEXT[]
    ),
    CONSTRAINT chk_issue_tags CHECK (
        issue_tags IS NULL OR
        issue_tags <@ ARRAY['price','taste','temperature','speed','portion']::TEXT[]
    ),
    CONSTRAINT chk_improve_tags CHECK (
        improve_tags IS NULL OR
        improve_tags <@ ARRAY['price','taste','temperature','speed','portion']::TEXT[]
    )
);

COMMENT ON TABLE order_feedback IS 'Квиз ОС после заказа. ОДИН квиз на заказ (решение от CODE BLACK v3.0). was_shown=TRUE → больше не показывать.';
COMMENT ON COLUMN order_feedback.is_positive IS '«Всё хорошо?» TRUE=Да / FALSE=Нет / NULL=закрыл без ответа';
COMMENT ON COLUMN order_feedback.positive_tags IS '[D] «Что нравится?» — заполняется если is_positive=TRUE. Теги: price, taste, prepared_as_wanted';
COMMENT ON COLUMN order_feedback.issue_tags IS '«Что смутило?» — заполняется если is_positive=FALSE';
COMMENT ON COLUMN order_feedback.improve_tags IS '«Что исправить?» — заполняется если is_positive=FALSE';
COMMENT ON COLUMN order_feedback.items_feedback IS 'ЗАРЕЗЕРВИРОВАНО: для возможного future per-item квиза (вопрос #5 заморожен). Сейчас NULL.';
COMMENT ON COLUMN order_feedback.was_shown IS 'Квиз был показан. Если TRUE и was_answered=FALSE — закрыл без ответа, больше не тревожить.';

CREATE INDEX idx_feedback_order ON order_feedback(order_id);
CREATE INDEX idx_feedback_customer ON order_feedback(customer_id);
CREATE INDEX idx_feedback_pending ON order_feedback(customer_id, was_shown)
    WHERE was_shown = FALSE;
CREATE INDEX idx_feedback_unanswered ON order_feedback(customer_id)
    WHERE was_shown = TRUE AND was_answered = FALSE;


-- ============================================================================
-- ЧАСТЬ G: РАСШИРЕНИЕ ТАБЛИЦЫ orders
-- ============================================================================

ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES mobile_customers(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS qr_token UUID UNIQUE DEFAULT gen_random_uuid(),
    ADD COLUMN IF NOT EXISTS qr_expires_at TIMESTAMP WITH TIME ZONE
        DEFAULT (NOW() + INTERVAL '24 hours'),
    -- Комментарий клиента (раньше p_comment в функции тихо терялся)
    ADD COLUMN IF NOT EXISTS customer_comment TEXT,
    -- [E] Чаевые через НЕТМОНЕТ — только фиксируем момент перехода
    -- Вся логика суммы и списания на стороне НЕТМОНЕТ
    -- tips_payment_id убран (v2.0 был избыточен)
    ADD COLUMN IF NOT EXISTS tips_initiated_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN orders.customer_id IS 'Клиент мобильного приложения. NULL для barista/kiosk заказов.';
COMMENT ON COLUMN orders.qr_token IS 'Токен для QR-кода отслеживания статуса (публичный endpoint)';
COMMENT ON COLUMN orders.qr_expires_at IS 'TTL QR-ссылки 24 часа';
COMMENT ON COLUMN orders.customer_comment IS 'Комментарий клиента к заказу из мобильного приложения';
COMMENT ON COLUMN orders.tips_initiated_at IS '[E] Момент когда клиент нажал «Оставить чаевые» и перешёл в НЕТМОНЕТ. Сам процесс и сумма — полностью на стороне НЕТМОНЕТ, мы не отслеживаем.';

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_qr_token ON orders(qr_token);
CREATE INDEX IF NOT EXISTS idx_orders_qr_active ON orders(qr_expires_at)
    WHERE qr_expires_at > NOW();


-- ============================================================================
-- ЧАСТЬ H: РАСШИРЕНИЕ ТАБЛИЦЫ payments
-- [F] Убран apple_pay — рынок РФ (CODE BLACK v3.0)
-- ============================================================================

ALTER TABLE payments
    DROP CONSTRAINT IF EXISTS chk_payment_method;

ALTER TABLE payments
    ADD CONSTRAINT chk_payment_method CHECK (
        -- apple_pay УДАЛЁН: v3.0 явно указывает — только карта + СБП для РФ
        payment_method IN ('card', 'cash', 'sbp', 'ya_pay')
    );

COMMENT ON CONSTRAINT chk_payment_method ON payments IS '[F] v3.0: card | cash | sbp | ya_pay. apple_pay удалён (рынок РФ).';


-- ============================================================================
-- ЧАСТЬ I: ФУНКЦИИ АВТОРИЗАЦИИ
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: send_otp (rate-limit: макс 5 отправок в час)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION send_otp(p_phone VARCHAR)
RETURNS VARCHAR(6) AS $$
DECLARE
    v_code VARCHAR(6);
    v_send_count INTEGER;
    v_last_sent TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Rate-limit: не более 5 SMS в час на номер
    SELECT otp_send_count, otp_last_sent_at
    INTO v_send_count, v_last_sent
    FROM mobile_customers
    WHERE phone = p_phone;

    IF FOUND AND v_last_sent IS NOT NULL
       AND v_last_sent > NOW() - INTERVAL '1 hour'
       AND v_send_count >= 5 THEN
        RAISE EXCEPTION 'Превышен лимит отправок SMS. Попробуйте через час.';
    END IF;

    -- Инвалидируем предыдущие активные OTP
    UPDATE mobile_otp_codes
    SET is_used = TRUE
    WHERE phone = p_phone AND is_used = FALSE AND expires_at > NOW();

    -- Генерируем новый код
    v_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');

    INSERT INTO mobile_otp_codes (phone, code, expires_at)
    VALUES (p_phone, v_code, NOW() + INTERVAL '5 minutes');

    -- Обновляем счётчик rate-limit
    UPDATE mobile_customers
    SET otp_send_count = CASE
            WHEN v_last_sent IS NULL OR v_last_sent < NOW() - INTERVAL '1 hour'
            THEN 1
            ELSE otp_send_count + 1
        END,
        otp_last_sent_at = NOW()
    WHERE phone = p_phone;

    -- В продакшене SMS через внешний провайдер
    -- RETURN v_code — только для тестирования
    RETURN v_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION send_otp IS 'Отправить OTP. Rate-limit: макс 5 SMS/час на номер. Инвалидирует предыдущие активные коды.';


-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: verify_otp
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION verify_otp(p_phone VARCHAR, p_code VARCHAR)
RETURNS TABLE (customer_id UUID, refresh_token UUID, is_new_customer BOOLEAN) AS $$
DECLARE
    v_otp RECORD;
    v_customer_id UUID;
    v_is_new BOOLEAN;
    v_refresh UUID;
BEGIN
    SELECT * INTO v_otp
    FROM mobile_otp_codes
    WHERE phone = p_phone AND is_used = FALSE AND expires_at > NOW()
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'OTP не найден или истёк';
    END IF;

    UPDATE mobile_otp_codes SET attempts = attempts + 1 WHERE id = v_otp.id;

    IF v_otp.attempts >= 5 THEN
        RAISE EXCEPTION 'Превышено количество попыток ввода кода';
    END IF;

    IF v_otp.code != p_code THEN
        RAISE EXCEPTION 'Неверный код';
    END IF;

    UPDATE mobile_otp_codes SET is_used = TRUE WHERE id = v_otp.id;

    -- Upsert клиента
    INSERT INTO mobile_customers (phone, last_login_at)
    VALUES (p_phone, NOW())
    ON CONFLICT (phone) DO UPDATE SET last_login_at = NOW()
    RETURNING id, (xmax = 0) INTO v_customer_id, v_is_new;

    v_refresh := gen_random_uuid();
    INSERT INTO mobile_sessions (customer_id, refresh_token, expires_at)
    VALUES (v_customer_id, v_refresh, NOW() + INTERVAL '30 days');

    RETURN QUERY SELECT v_customer_id, v_refresh, v_is_new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: refresh_mobile_session (ротация токена)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION refresh_mobile_session(p_refresh_token UUID)
RETURNS TABLE (customer_id UUID, new_refresh_token UUID) AS $$
DECLARE
    v_session RECORD;
    v_new UUID;
BEGIN
    SELECT * INTO v_session
    FROM mobile_sessions
    WHERE refresh_token = p_refresh_token AND is_active = TRUE AND expires_at > NOW()
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Сессия не найдена или истекла';
    END IF;

    v_new := gen_random_uuid();

    UPDATE mobile_sessions SET is_active = FALSE WHERE id = v_session.id;

    INSERT INTO mobile_sessions (customer_id, refresh_token, device_info, ip_address, expires_at)
    VALUES (v_session.customer_id, v_new, v_session.device_info,
            v_session.ip_address, NOW() + INTERVAL '30 days');

    RETURN QUERY SELECT v_session.customer_id, v_new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: logout_mobile_session
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION logout_mobile_session(p_refresh_token UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE mobile_sessions
    SET is_active = FALSE
    WHERE refresh_token = p_refresh_token AND is_active = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: update_push_consent  [B]
-- Сохранить решение по push-уведомлениям (три состояния v3.0)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_push_consent(
    p_customer_id UUID,
    p_status VARCHAR,        -- 'granted' | 'denied' | 'ask_again'
    p_push_token TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    IF p_status NOT IN ('granted', 'denied', 'ask_again') THEN
        RAISE EXCEPTION 'Недопустимый статус согласия: %', p_status;
    END IF;

    UPDATE mobile_customers
    SET push_consent_status = p_status,
        -- Токен сохраняем только при granted
        push_token = CASE
            WHEN p_status = 'granted' AND p_push_token IS NOT NULL
            THEN p_push_token
            WHEN p_status = 'denied' THEN NULL  -- чистим токен при запрете
            ELSE push_token                      -- ask_again — не трогаем токен
        END,
        updated_at = NOW()
    WHERE id = p_customer_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Клиент не найден';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION update_push_consent IS '[B] Сохранить решение по push. granted=отправляем | denied=не отправляем | ask_again=спросить снова при следующем входе.';


-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: update_preferred_tenant  [A]
-- Сохранить выбранную точку (авто или вручную)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_preferred_tenant(
    p_customer_id UUID,
    p_tenant_id UUID,
    p_geo_lat DECIMAL DEFAULT NULL,
    p_geo_lon DECIMAL DEFAULT NULL,
    p_city VARCHAR DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE mobile_customers
    SET preferred_tenant_id = p_tenant_id,
        geo_lat = COALESCE(p_geo_lat, geo_lat),
        geo_lon = COALESCE(p_geo_lon, geo_lon),
        city    = COALESCE(p_city, city),
        geo_updated_at = CASE WHEN p_geo_lat IS NOT NULL THEN NOW() ELSE geo_updated_at END,
        updated_at = NOW()
    WHERE id = p_customer_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Клиент не найден';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION update_preferred_tenant IS '[A] Сохранить выбранную точку и геолокацию. Вызывать при авто-определении и ручном выборе из списка/карты.';


-- ============================================================================
-- ЧАСТЬ J: ФУНКЦИИ КОРЗИНЫ (Ghost Bar)
-- ============================================================================

CREATE OR REPLACE FUNCTION update_mobile_cart(
    p_customer_id UUID,
    p_tenant_id UUID,
    p_items JSONB,
    p_total_amount DECIMAL(10,2)
)
RETURNS VOID AS $$
BEGIN
    PERFORM 1 FROM mobile_customers
    WHERE id = p_customer_id AND is_active = TRUE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Клиент не найден или неактивен';
    END IF;

    INSERT INTO mobile_carts (customer_id, tenant_id, items, total_amount, expires_at)
    VALUES (p_customer_id, p_tenant_id, p_items, p_total_amount, NOW() + INTERVAL '24 hours')
    ON CONFLICT (customer_id, tenant_id) DO UPDATE
    SET items        = EXCLUDED.items,
        total_amount = EXCLUDED.total_amount,
        expires_at   = NOW() + INTERVAL '24 hours',
        updated_at   = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION update_mobile_cart IS 'Обновить корзину (Ghost Bar). TTL сбрасывается на 24ч при каждом изменении.';


CREATE OR REPLACE FUNCTION clear_mobile_cart(p_customer_id UUID, p_tenant_id UUID)
RETURNS VOID AS $$
BEGIN
    DELETE FROM mobile_carts
    WHERE customer_id = p_customer_id AND tenant_id = p_tenant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================================
-- ЧАСТЬ K: ФУНКЦИИ ЗАКАЗА
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: create_order_from_mobile
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION create_order_from_mobile(
    p_customer_id UUID,
    p_tenant_id UUID,
    p_items JSONB,
    p_payment_method VARCHAR(50),
    p_comment TEXT DEFAULT NULL
)
RETURNS TABLE (
    order_id UUID,
    order_number VARCHAR(20),
    payment_id UUID,
    qr_token UUID
) AS $$
DECLARE
    v_order_id UUID;
    v_order_number VARCHAR(20);
    v_payment_id UUID;
    v_qr_token UUID;
    v_item JSONB;
    v_enabled BOOLEAN;
    v_sold_out BOOLEAN;
    v_total DECIMAL(10,2) := 0;
    v_completed_orders INTEGER;
BEGIN
    PERFORM 1 FROM mobile_customers
    WHERE id = p_customer_id AND is_active = TRUE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Клиент не найден или неактивен';
    END IF;

    -- Валидация товаров
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
        SELECT is_enabled, is_sold_out INTO v_enabled, v_sold_out
        FROM product_tenant_settings
        WHERE tenant_id = p_tenant_id
          AND product_id = (v_item->>'product_id')::UUID;

        IF NOT FOUND OR NOT v_enabled THEN
            RAISE EXCEPTION 'Продукт % недоступен', v_item->>'product_id';
        END IF;
        IF v_sold_out THEN
            RAISE EXCEPTION 'Продукт % раскуплен', v_item->>'product_id';
        END IF;

        v_total := v_total
            + (v_item->>'price')::DECIMAL(10,2)
            * (v_item->>'quantity')::INTEGER;
    END LOOP;

    -- Создаём заказ
    INSERT INTO orders (
        tenant_id, source, status, customer_id,
        total_amount, discount_amount, final_amount,
        customer_comment, created_at
    ) VALUES (
        p_tenant_id, 'mobile', 'new', p_customer_id,
        v_total, 0, v_total, p_comment, NOW()
    )
    RETURNING id, order_number, qr_token INTO v_order_id, v_order_number, v_qr_token;

    -- Позиции заказа
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
        INSERT INTO order_items (
            order_id, product_id, quantity, modifier_options,
            unit_price, total_price
        ) VALUES (
            v_order_id,
            (v_item->>'product_id')::UUID,
            (v_item->>'quantity')::INTEGER,
            v_item->'modifier_options',
            (v_item->>'price')::DECIMAL(10,2),
            (v_item->>'price')::DECIMAL(10,2) * (v_item->>'quantity')::INTEGER
        );
    END LOOP;

    -- Платёж
    INSERT INTO payments (tenant_id, order_id, amount, payment_method, status, created_at)
    VALUES (p_tenant_id, v_order_id, v_total, p_payment_method, 'pending', NOW())
    RETURNING id INTO v_payment_id;

    -- Очищаем корзину
    PERFORM clear_mobile_cart(p_customer_id, p_tenant_id);

    -- Создаём заготовку квиза ОС
    INSERT INTO order_feedback (order_id, customer_id, was_shown)
    VALUES (v_order_id, p_customer_id, FALSE);

    -- [C] Проверяем онбординг: если это 2-й выполненный заказ — закрываем подсказки
    -- Подсчёт идёт по issued заказам (завершённым, не новым)
    SELECT COUNT(*) INTO v_completed_orders
    FROM orders
    WHERE customer_id = p_customer_id AND status = 'issued';

    IF v_completed_orders >= 1 THEN
        -- При создании это будет уже 2-й или более — закрываем онбординг
        UPDATE mobile_customers
        SET onboarding_completed_at = COALESCE(onboarding_completed_at, NOW())
        WHERE id = p_customer_id AND onboarding_completed_at IS NULL;
    END IF;

    RETURN QUERY SELECT v_order_id, v_order_number, v_payment_id, v_qr_token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION create_order_from_mobile IS 'Создать заказ из мобильного приложения. Очищает корзину, создаёт заготовку квиза ОС, проверяет онбординг.';


-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: get_order_status_by_qr (публичный endpoint)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_order_status_by_qr(p_qr_token UUID)
RETURNS TABLE (
    order_id UUID, order_number VARCHAR(20), status VARCHAR(50),
    source VARCHAR(50), items_count INTEGER,
    total_amount DECIMAL(10,2), final_amount DECIMAL(10,2),
    payment_status VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE, updated_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE v_order RECORD;
BEGIN
    SELECT o.id, o.order_number, o.status, o.source,
           o.total_amount, o.final_amount, o.created_at, o.updated_at,
           p.status AS payment_status,
           (SELECT COUNT(*) FROM order_items WHERE order_id = o.id) AS items_count
    INTO v_order
    FROM orders o
    LEFT JOIN payments p ON p.order_id = o.id
    WHERE o.qr_token = p_qr_token AND o.qr_expires_at > NOW();

    IF NOT FOUND THEN
        RAISE EXCEPTION 'QR-код не найден или истёк';
    END IF;

    order_id       := v_order.id;
    order_number   := v_order.order_number;
    status         := v_order.status;
    source         := v_order.source;
    items_count    := v_order.items_count;
    total_amount   := v_order.total_amount;
    final_amount   := v_order.final_amount;
    payment_status := v_order.payment_status;
    created_at     := v_order.created_at;
    updated_at     := v_order.updated_at;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;


-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: get_customer_orders — полная история заказов
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_customer_orders(
    p_customer_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    order_id UUID, order_number VARCHAR(20), tenant_id UUID,
    status VARCHAR(50), total_amount DECIMAL(10,2), final_amount DECIMAL(10,2),
    payment_method VARCHAR(50), payment_status VARCHAR(50),
    items_count INTEGER, created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT o.id, o.order_number, o.tenant_id, o.status,
           o.total_amount, o.final_amount,
           p.payment_method, p.status AS payment_status,
           (SELECT COUNT(*) FROM order_items WHERE order_id = o.id)::INTEGER,
           o.created_at
    FROM orders o
    LEFT JOIN payments p ON p.order_id = o.id
    WHERE o.customer_id = p_customer_id
    ORDER BY o.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;


-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: get_last_orders_for_ghost_bar  [G]
-- Лёгкий запрос для Ghost Bar: последние 32 заказа, 3 уникальных названия
-- ============================================================================

CREATE OR REPLACE FUNCTION get_last_orders_for_ghost_bar(
    p_customer_id UUID,
    p_tenant_id UUID,
    p_limit INTEGER DEFAULT 3        -- сколько последних заказов показать в Ghost Bar
)
RETURNS TABLE (
    order_id UUID,
    order_number VARCHAR(20),
    total_amount DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE,
    product_names TEXT[],            -- уникальные названия (до 3 штук)
    payment_method VARCHAR(50)       -- для повторного заказа одним тапом
) AS $$
BEGIN
    RETURN QUERY
    -- [G] История: берём последние 32 выполненных заказа (CODE BLACK v3.0)
    WITH history AS (
        SELECT o.id, o.order_number, o.final_amount, o.created_at
        FROM orders o
        WHERE o.customer_id = p_customer_id
          AND o.tenant_id = p_tenant_id
          AND o.status = 'issued'
        ORDER BY o.created_at DESC
        LIMIT 32
    )
    SELECT
        h.id,
        h.order_number,
        h.final_amount,
        h.created_at,
        -- До 3 уникальных названий товаров из заказа
        ARRAY(
            SELECT DISTINCT pr.name
            FROM order_items oi
            JOIN products pr ON oi.product_id = pr.id
            WHERE oi.order_id = h.id
            LIMIT 3
        ) AS product_names,
        p.payment_method
    FROM history h
    LEFT JOIN payments p ON p.order_id = h.id AND p.status = 'paid'
    ORDER BY h.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION get_last_orders_for_ghost_bar IS '[G] Ghost Bar: последние 32 заказа из истории, возвращаем p_limit (=3 по умолч). Уникальные названия, без дублей порядка (CODE BLACK v3.0 п.1б).';


-- ============================================================================
-- ЧАСТЬ L: ФУНКЦИИ КВИЗА ОБРАТНОЙ СВЯЗИ  [D]
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: mark_feedback_shown — пользователь закрыл квиз без ответа
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION mark_feedback_shown(p_order_id UUID, p_customer_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE order_feedback
    SET was_shown = TRUE, shown_at = NOW()
    WHERE order_id = p_order_id
      AND customer_id = p_customer_id
      AND was_shown = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION mark_feedback_shown IS 'Отметить что квиз показали. was_shown=TRUE, was_answered=FALSE → больше не показывать (CODE BLACK v3.0).';


-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: submit_order_feedback — сохранить ответы квиза
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION submit_order_feedback(
    p_order_id UUID,
    p_customer_id UUID,
    p_is_positive BOOLEAN,
    p_positive_tags TEXT[] DEFAULT NULL,    -- [D] если is_positive=TRUE
    p_issue_tags TEXT[] DEFAULT NULL,       -- если is_positive=FALSE
    p_improve_tags TEXT[] DEFAULT NULL,
    p_rating SMALLINT DEFAULT NULL,
    p_comment TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE order_feedback
    SET is_positive   = p_is_positive,
        positive_tags = p_positive_tags,
        issue_tags    = p_issue_tags,
        improve_tags  = p_improve_tags,
        rating        = p_rating,
        comment       = p_comment,
        was_shown     = TRUE,
        was_answered  = TRUE,
        shown_at      = COALESCE(shown_at, NOW()),
        answered_at   = NOW()
    WHERE order_id    = p_order_id
      AND customer_id = p_customer_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Квиз для заказа % не найден', p_order_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION submit_order_feedback IS '[D] Сохранить ответы квиза. Один квиз на заказ (решение CODE BLACK v3.0, вопрос #5).';


-- ============================================================================
-- ЧАСТЬ M: ФУНКЦИЯ ОЧИСТКИ (cron каждый час)
-- ============================================================================

CREATE OR REPLACE FUNCTION cleanup_mobile_data()
RETURNS INTEGER AS $$
DECLARE
    v_otp INTEGER;
    v_sessions INTEGER;
    v_carts INTEGER;
BEGIN
    DELETE FROM mobile_otp_codes WHERE expires_at < NOW() AND is_used = FALSE;
    GET DIAGNOSTICS v_otp = ROW_COUNT;

    UPDATE mobile_sessions SET is_active = FALSE
    WHERE expires_at < NOW() AND is_active = TRUE;
    GET DIAGNOSTICS v_sessions = ROW_COUNT;

    -- [G] Удалить просроченные корзины (TTL 24ч, CODE BLACK v3.0 п.7)
    DELETE FROM mobile_carts WHERE expires_at < NOW();
    GET DIAGNOSTICS v_carts = ROW_COUNT;

    RETURN v_otp + v_sessions + v_carts;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION cleanup_mobile_data IS 'Очистка OTP / сессий / корзин. Запускать cron каждый час.';


-- ============================================================================
-- ЧАСТЬ N: VIEWS
-- ============================================================================

CREATE OR REPLACE VIEW v_mobile_order_status AS
SELECT
    o.id AS order_id, o.qr_token, o.order_number,
    o.status, o.source, o.tenant_id, o.customer_id,
    o.customer_comment,
    (SELECT COUNT(*) FROM order_items WHERE order_id = o.id) AS items_count,
    o.total_amount, o.final_amount,
    o.tips_initiated_at,     -- [E] момент перехода в НЕТМОНЕТ
    p.payment_method, p.status AS payment_status,
    o.qr_expires_at, o.created_at, o.updated_at
FROM orders o
LEFT JOIN payments p ON p.order_id = o.id
WHERE o.qr_token IS NOT NULL;

COMMENT ON VIEW v_mobile_order_status IS 'Статус заказа по QR-токену (публичный endpoint, без авторизации)';


CREATE OR REPLACE VIEW v_mobile_active_orders AS
SELECT
    o.id AS order_id, o.order_number, o.tenant_id,
    o.customer_id,
    mc.phone AS customer_phone,
    COALESCE(mc.first_name || ' ' || mc.last_name, mc.phone) AS customer_name,
    o.status, o.total_amount, o.final_amount,
    o.customer_comment,
    p.payment_method, p.status AS payment_status,
    o.qr_token, o.created_at
FROM orders o
JOIN mobile_customers mc ON o.customer_id = mc.id
LEFT JOIN payments p ON p.order_id = o.id
WHERE o.source = 'mobile'
  AND o.status NOT IN ('issued', 'cancelled');

COMMENT ON VIEW v_mobile_active_orders IS 'Активные мобильные заказы для экрана баристы';


-- ============================================================================
-- ЧАСТЬ O: ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE mobile_customers        ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_sessions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_payment_methods  ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_carts            ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_feedback          ENABLE ROW LEVEL SECURITY;

-- mobile_customers
CREATE POLICY rls_mc_read ON mobile_customers FOR SELECT USING (
    id = NULLIF(current_setting('app.current_customer_id', TRUE), '')::UUID
    OR EXISTS (
        SELECT 1 FROM user_roles ur JOIN roles r ON ur.role_id = r.id
        WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
        AND r.code IN ('office_manager', 'ук_global_admin', 'ук_country_manager')
    )
);
CREATE POLICY rls_mc_write ON mobile_customers FOR UPDATE USING (
    id = NULLIF(current_setting('app.current_customer_id', TRUE), '')::UUID
    OR EXISTS (
        SELECT 1 FROM user_roles ur JOIN roles r ON ur.role_id = r.id
        WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
        AND r.code IN ('office_manager', 'ук_global_admin', 'ук_country_manager')
    )
);

-- mobile_sessions
CREATE POLICY rls_ms_read ON mobile_sessions FOR SELECT USING (
    customer_id = NULLIF(current_setting('app.current_customer_id', TRUE), '')::UUID
    OR EXISTS (
        SELECT 1 FROM user_roles ur JOIN roles r ON ur.role_id = r.id
        WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
        AND r.code IN ('ук_global_admin', 'ук_country_manager')
    )
);
CREATE POLICY rls_ms_write ON mobile_sessions FOR ALL USING (
    customer_id = NULLIF(current_setting('app.current_customer_id', TRUE), '')::UUID
    OR EXISTS (
        SELECT 1 FROM user_roles ur JOIN roles r ON ur.role_id = r.id
        WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
        AND r.code IN ('ук_global_admin', 'ук_country_manager')
    )
);

-- mobile_payment_methods: только свои карты
CREATE POLICY rls_pm_read ON mobile_payment_methods FOR SELECT USING (
    customer_id = NULLIF(current_setting('app.current_customer_id', TRUE), '')::UUID
    OR EXISTS (
        SELECT 1 FROM user_roles ur JOIN roles r ON ur.role_id = r.id
        WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
        AND r.code IN ('ук_global_admin')
    )
);
CREATE POLICY rls_pm_write ON mobile_payment_methods FOR ALL USING (
    customer_id = NULLIF(current_setting('app.current_customer_id', TRUE), '')::UUID
);

-- mobile_carts: только своя корзина
CREATE POLICY rls_cart_read ON mobile_carts FOR SELECT USING (
    customer_id = NULLIF(current_setting('app.current_customer_id', TRUE), '')::UUID
);
CREATE POLICY rls_cart_write ON mobile_carts FOR ALL USING (
    customer_id = NULLIF(current_setting('app.current_customer_id', TRUE), '')::UUID
);

-- order_feedback
CREATE POLICY rls_fb_read ON order_feedback FOR SELECT USING (
    customer_id = NULLIF(current_setting('app.current_customer_id', TRUE), '')::UUID
    OR EXISTS (
        SELECT 1 FROM user_roles ur JOIN roles r ON ur.role_id = r.id
        WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
        AND r.code IN ('office_manager', 'ук_global_admin', 'ук_country_manager')
    )
);
CREATE POLICY rls_fb_write ON order_feedback FOR ALL USING (
    customer_id = NULLIF(current_setting('app.current_customer_id', TRUE), '')::UUID
    OR EXISTS (
        SELECT 1 FROM user_roles ur JOIN roles r ON ur.role_id = r.id
        WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
        AND r.code IN ('office_manager', 'ук_global_admin', 'ук_country_manager')
    )
);


-- ============================================================================
-- ЧАСТЬ P: SEED DATA
-- ============================================================================

BEGIN;
SET LOCAL row_security = off;

-- 1. Тестовый клиент
INSERT INTO mobile_customers (
    phone, email, first_name, last_name, is_active,
    push_consent_status, city
) VALUES (
    '+79000000001', 'test@example.com', 'Тест', 'Клиент', TRUE,
    'granted', 'Москва'
)
ON CONFLICT (phone) DO UPDATE SET
    email               = EXCLUDED.email,
    first_name          = EXCLUDED.first_name,
    last_name           = EXCLUDED.last_name,
    push_consent_status = EXCLUDED.push_consent_status,
    city                = EXCLUDED.city;

-- 2. Тестовый метод оплаты
INSERT INTO mobile_payment_methods (customer_id, payment_type, card_masked, card_brand, is_default)
SELECT mc.id, 'card', '**** 0001', 'Mir', TRUE
FROM mobile_customers mc
WHERE mc.phone = '+79000000001'
  AND NOT EXISTS (
      SELECT 1 FROM mobile_payment_methods pm WHERE pm.customer_id = mc.id
  );

-- 3. Тестовый заказ
INSERT INTO orders (
    tenant_id, source, status, customer_id,
    total_amount, discount_amount, final_amount,
    order_number, qr_token, qr_expires_at, customer_comment
)
SELECT
    '00000000-0000-0000-0000-000000000001',
    'mobile', 'preparing', mc.id,
    450.00, 0, 450.00,
    '#TEST-MOB-001', gen_random_uuid(),
    NOW() + INTERVAL '24 hours',
    'Без сахара, побольше льда'
FROM mobile_customers mc
WHERE mc.phone = '+79000000001'
  AND NOT EXISTS (SELECT 1 FROM orders WHERE order_number = '#TEST-MOB-001');

-- 4. Заготовка квиза ОС для тестового заказа
INSERT INTO order_feedback (order_id, customer_id, was_shown)
SELECT o.id, o.customer_id, FALSE
FROM orders o
WHERE o.order_number = '#TEST-MOB-001'
  AND NOT EXISTS (SELECT 1 FROM order_feedback f WHERE f.order_id = o.id);

COMMIT;


-- ============================================================================
-- КОНЕЦ МИГРАЦИЙ ЭТАПА 8 — ВЕРСИЯ 2.1 (ФИНАЛЬНАЯ)
-- ============================================================================

/*
================================================================================
ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ

АВТОРИЗАЦИЯ
  SELECT send_otp('+79001234567');
  SELECT * FROM verify_otp('+79001234567', '123456');
  SELECT * FROM refresh_mobile_session('refresh-token-uuid');
  SELECT logout_mobile_session('refresh-token-uuid');

ГЕОЛОКАЦИЯ И ТОЧКА  [A]
  SELECT update_preferred_tenant(
      'customer-uuid', 'tenant-uuid',
      55.7558, 37.6173, 'Москва'
  );

PUSH-СОГЛАСИЕ  [B]
  SELECT update_push_consent('customer-uuid', 'granted', 'fcm-token');
  SELECT update_push_consent('customer-uuid', 'denied');
  SELECT update_push_consent('customer-uuid', 'ask_again');

КОРЗИНА / GHOST BAR
  SELECT update_mobile_cart('customer-uuid', 'tenant-uuid',
      '[{"product_id":"...","quantity":1,"price":250.00}]'::JSONB, 250.00);

  -- Ghost Bar: последние 3 заказа для повторного заказа
  SELECT * FROM get_last_orders_for_ghost_bar('customer-uuid', 'tenant-uuid', 3);

СОЗДАТЬ ЗАКАЗ
  SELECT * FROM create_order_from_mobile(
      'customer-uuid', 'tenant-uuid',
      '[{"product_id":"...","quantity":2,"price":350.00}]'::JSONB,
      'card', 'Без сахара'
  );

QR-СТАТУС (публичный, без авторизации)
  SELECT * FROM get_order_status_by_qr('qr-token-uuid');

ИСТОРИЯ ЗАКАЗОВ
  SELECT * FROM get_customer_orders('customer-uuid', 20, 0);

КВИЗ ОБРАТНОЙ СВЯЗИ
  -- Показали, пользователь закрыл (больше не спрашиваем):
  SELECT mark_feedback_shown('order-uuid', 'customer-uuid');

  -- Пользователь ответил «Да, всё хорошо»:
  SELECT submit_order_feedback('order-uuid', 'customer-uuid',
      TRUE, ARRAY['taste','prepared_as_wanted'], NULL, NULL, 5, NULL);

  -- Пользователь ответил «Нет»:
  SELECT submit_order_feedback('order-uuid', 'customer-uuid',
      FALSE, NULL,
      ARRAY['taste','temperature'],  -- что смутило
      ARRAY['temperature'],          -- что исправить
      2, 'Кофе был холодный');

КАРТЫ
  SELECT * FROM mobile_payment_methods
  WHERE customer_id = 'customer-uuid' AND is_active = TRUE;

ЧАЕВЫЕ НЕТМОНЕТ  [E]
  -- При нажатии кнопки «Оставить чаевые» — редирект в НЕТМОНЕТ
  -- После возврата пользователя — фиксируем момент:
  UPDATE orders SET tips_initiated_at = NOW() WHERE id = 'order-uuid';

ОЧИСТКА (cron каждый час)
  SELECT cleanup_mobile_data();

================================================================================
ИЗМЕНЕНИЯ v2.1 vs v2.0

[A] mobile_customers + preferred_tenant_id
    Точка кофейни сохраняется при авто/ручном выборе.
    Подставляется при следующем входе без повторного запроса.
    Функция: update_preferred_tenant()

[B] push_enabled BOOLEAN → push_consent_status VARCHAR(20)
    Три состояния: granted | denied | ask_again
    ask_again = «Только в этот раз» (CODE BLACK v3.0) — спросить снова
    Функция: update_push_consent(). При denied — токен обнуляется.

[C] mobile_customers + onboarding_completed_at
    NULL = онбординг идёт (первые 2 заказа, подсказки показываем).
    NOT NULL = онбординг завершён, подсказки больше не показываем.
    Проставляется автоматически в create_order_from_mobile()
    при втором выполненном заказе.

[D] order_feedback + positive_tags TEXT[]
    Добавлен шаг «Что нравится?» для ветки is_positive=TRUE.
    Теги: price, taste, prepared_as_wanted.
    + items_feedback JSONB зарезервирован для будущего per-item (вопрос #5).

    ✅ РЕШЕНИЕ CODE BLACK v3.0, вопрос #5:
    «ОС при нескольких позициях — ОДИН квиз на весь заказ»
    Обоснование: снижает усталость, индустриальный стандарт,
    соответствует UX coffee take-away формата.

[E] orders: tips_payment_id удалён → tips_initiated_at
    Чаевые = редирект в НЕТМОНЕТ, наше приложение только инициирует переход.
    Сумма и списание — полностью на стороне НЕТМОНЕТ.
    tips_initiated_at фиксирует момент тапа кнопки.

[F] payments CHECK: убран apple_pay
    Допустимые методы: card | cash | sbp | ya_pay
    CODE BLACK v3.0 явно исключает Apple Pay для рынка РФ.

[G] get_last_orders_for_ghost_bar: history LIMIT 32
    CODE BLACK v3.0 п.1б: «показывать последние 32 заказа из ЛК».
    Функция возвращает p_limit (=3) самых свежих из этих 32.

================================================================================
ОТКРЫТЫЕ ВОПРОСЫ

| # | Вопрос                                              | Статус         |
|---|-----------------------------------------------------|----------------|
| 5 | ОС при нескольких позициях — один квиз или по каждой| ✅ ЗАКРЫТ: один |
| - | items_feedback JSONB зарезервирован для future per-item (если передумают) | 🔵 Резерв |

================================================================================
*/
apps-fileview.texmex_20260501.02_p0
ядро 8.2.txt
ядро 8.2.txt. На экране.