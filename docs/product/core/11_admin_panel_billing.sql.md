
```sql
-- ============================================================================
-- SQL МИГРАЦИИ ДЛЯ СИСТЕМЫ КОФЕЕН (POSTGRESQL)
-- ЭТАП 12: ADMIN PANEL УК + ВТОРАЯ ТОЧКА
-- Версия 1.2 - Исправлено дублирующееся условие в SEED DATA
-- ============================================================================

-- ============================================================================
-- ЧАСТЬ A: РАСШИРЕНИЕ ТАБЛИЦЫ tenants
-- ============================================================================

ALTER TABLE tenants 
    ADD COLUMN IF NOT EXISTS type VARCHAR(50) NOT NULL DEFAULT 'coffee_shop',
    ADD COLUMN IF NOT EXISTS country VARCHAR(2) DEFAULT 'RU',
    ADD COLUMN IF NOT EXISTS city VARCHAR(100),
    ADD COLUMN IF NOT EXISTS address TEXT,
    ADD COLUMN IF NOT EXISTS phone VARCHAR(20),
    ADD COLUMN IF NOT EXISTS timezone VARCHAR(50) DEFAULT 'Europe/Moscow',
    ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'RUB',
    ADD COLUMN IF NOT EXISTS logo_url VARCHAR(500),
    ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS trial_until TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS plan_id UUID,
    ADD COLUMN IF NOT EXISTS meta JSONB;

ALTER TABLE tenants
    DROP CONSTRAINT IF EXISTS chk_tenant_type;

ALTER TABLE tenants
    ADD CONSTRAINT chk_tenant_type 
    CHECK (type IN ('coffee_shop', 'production_kitchen', 'headquarters'));

COMMENT ON COLUMN tenants.type IS 'Тип тенанта: coffee_shop, production_kitchen, headquarters';
COMMENT ON COLUMN tenants.country IS 'Код страны (ISO 3166-1 alpha-2)';
COMMENT ON COLUMN tenants.city IS 'Город';
COMMENT ON COLUMN tenants.address IS 'Адрес';
COMMENT ON COLUMN tenants.phone IS 'Телефон';
COMMENT ON COLUMN tenants.timezone IS 'Часовой пояс';
COMMENT ON COLUMN tenants.currency IS 'Валюта (ISO 4217)';
COMMENT ON COLUMN tenants.logo_url IS 'URL логотипа';
COMMENT ON COLUMN tenants.is_demo IS 'Демо-точка для тестирования';
COMMENT ON COLUMN tenants.trial_until IS 'До какого времени активен триальный период';
COMMENT ON COLUMN tenants.plan_id IS 'Текущий тарифный план';
COMMENT ON COLUMN tenants.meta IS 'Дополнительные данные (соцсети, часы работы)';

CREATE INDEX IF NOT EXISTS idx_tenants_type ON tenants(type);
CREATE INDEX IF NOT EXISTS idx_tenants_country_city ON tenants(country, city);
CREATE INDEX IF NOT EXISTS idx_tenants_is_demo ON tenants(is_demo);

-- ============================================================================
-- ЧАСТЬ B: ТАБЛИЦА billing_plans
-- ============================================================================

CREATE TABLE IF NOT EXISTS billing_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price_monthly DECIMAL(10,2) NOT NULL DEFAULT 0,
    price_yearly DECIMAL(10,2),
    max_devices INTEGER,
    max_products INTEGER,
    max_staff INTEGER,
    features JSONB NOT NULL DEFAULT '{}'::JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_billing_price CHECK (price_monthly >= 0)
);

COMMENT ON TABLE billing_plans IS 'Тарифные планы УК';
COMMENT ON COLUMN billing_plans.id IS 'Уникальный идентификатор плана';
COMMENT ON COLUMN billing_plans.code IS 'Код плана (starter, pro, enterprise)';
COMMENT ON COLUMN billing_plans.name IS 'Название плана';
COMMENT ON COLUMN billing_plans.description IS 'Описание плана';
COMMENT ON COLUMN billing_plans.price_monthly IS 'Стоимость в месяц';
COMMENT ON COLUMN billing_plans.price_yearly IS 'Стоимость в год (NULL = нет годового плана)';
COMMENT ON COLUMN billing_plans.max_devices IS 'Максимум устройств (NULL = безлимит)';
COMMENT ON COLUMN billing_plans.max_products IS 'Максимум продуктов в меню (NULL = безлимит)';
COMMENT ON COLUMN billing_plans.max_staff IS 'Максимум сотрудников (NULL = безлимит)';
COMMENT ON COLUMN billing_plans.features IS 'Включённые функции (JSONB)';
COMMENT ON COLUMN billing_plans.is_active IS 'Активность плана';
COMMENT ON COLUMN billing_plans.sort_order IS 'Порядок сортировки';
COMMENT ON COLUMN billing_plans.created_at IS 'Дата создания';
COMMENT ON COLUMN billing_plans.updated_at IS 'Дата обновления';

CREATE INDEX idx_billing_plans_code ON billing_plans(code);
CREATE INDEX idx_billing_plans_active_sort ON billing_plans(is_active, sort_order);

CREATE TRIGGER trg_billing_plans_updated_at
    BEFORE UPDATE ON billing_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Добавляем FK на billing_plans после создания таблицы
ALTER TABLE tenants 
    DROP CONSTRAINT IF EXISTS fk_tenants_plan;

ALTER TABLE tenants
    ADD CONSTRAINT fk_tenants_plan 
    FOREIGN KEY (plan_id) REFERENCES billing_plans(id) ON DELETE SET NULL;

-- ============================================================================
-- ЧАСТЬ C: ТАБЛИЦА billing_subscriptions
-- ============================================================================

CREATE TABLE IF NOT EXISTS billing_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES billing_plans(id) ON DELETE RESTRICT,
    billing_period VARCHAR(20) NOT NULL DEFAULT 'monthly',
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    amount_paid DECIMAL(10,2) DEFAULT 0,
    payment_reference VARCHAR(255),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_billing_period CHECK (billing_period IN ('monthly', 'yearly', 'trial', 'free')),
    CONSTRAINT chk_subscription_status CHECK (status IN ('active', 'cancelled', 'expired', 'past_due')),
    CONSTRAINT chk_amount_paid CHECK (amount_paid >= 0)
);

COMMENT ON TABLE billing_subscriptions IS 'История подписок тенантов';
COMMENT ON COLUMN billing_subscriptions.id IS 'Уникальный идентификатор подписки';
COMMENT ON COLUMN billing_subscriptions.tenant_id IS 'Тенант';
COMMENT ON COLUMN billing_subscriptions.plan_id IS 'Тарифный план';
COMMENT ON COLUMN billing_subscriptions.billing_period IS 'Период оплаты: monthly, yearly, trial, free';
COMMENT ON COLUMN billing_subscriptions.status IS 'Статус: active, cancelled, expired, past_due';
COMMENT ON COLUMN billing_subscriptions.started_at IS 'Дата начала';
COMMENT ON COLUMN billing_subscriptions.expires_at IS 'Дата окончания';
COMMENT ON COLUMN billing_subscriptions.cancelled_at IS 'Дата отмены';
COMMENT ON COLUMN billing_subscriptions.amount_paid IS 'Сумма оплаты';
COMMENT ON COLUMN billing_subscriptions.payment_reference IS 'Внешний ID платежа';
COMMENT ON COLUMN billing_subscriptions.created_by IS 'Кто создал подписку';
COMMENT ON COLUMN billing_subscriptions.created_at IS 'Дата создания';
COMMENT ON COLUMN billing_subscriptions.updated_at IS 'Дата обновления';

CREATE INDEX idx_billing_subscriptions_tenant_status ON billing_subscriptions(tenant_id, status);
CREATE INDEX idx_billing_subscriptions_plan ON billing_subscriptions(plan_id);
CREATE INDEX idx_billing_subscriptions_expires ON billing_subscriptions(expires_at) WHERE status = 'active';

CREATE TRIGGER trg_billing_subscriptions_updated_at
    BEFORE UPDATE ON billing_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ЧАСТЬ D: ТАБЛИЦА admin_audit_log
-- ============================================================================

CREATE TABLE IF NOT EXISTS admin_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    tenant_id UUID REFERENCES tenants(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    old_value JSONB,
    new_value JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE admin_audit_log IS 'Аудит действий администраторов УК и менеджеров точек (immutable лог)';
COMMENT ON COLUMN admin_audit_log.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN admin_audit_log.user_id IS 'Пользователь выполнивший действие';
COMMENT ON COLUMN admin_audit_log.tenant_id IS 'Тенант в контексте которого выполнено действие';
COMMENT ON COLUMN admin_audit_log.action IS 'Действие (tenant.create, user.role_assign, billing.plan_change)';
COMMENT ON COLUMN admin_audit_log.entity_type IS 'Тип объекта (tenant, user, product, promo_code)';
COMMENT ON COLUMN admin_audit_log.entity_id IS 'ID изменённого объекта';
COMMENT ON COLUMN admin_audit_log.old_value IS 'Состояние до изменений';
COMMENT ON COLUMN admin_audit_log.new_value IS 'Состояние после изменений';
COMMENT ON COLUMN admin_audit_log.ip_address IS 'IP адрес';
COMMENT ON COLUMN admin_audit_log.user_agent IS 'User agent';
COMMENT ON COLUMN admin_audit_log.created_at IS 'Время действия';

-- Индексы для аудит-лога
CREATE INDEX idx_admin_audit_user_created ON admin_audit_log(user_id, created_at DESC);
CREATE INDEX idx_admin_audit_tenant_created ON admin_audit_log(tenant_id, created_at DESC);
CREATE INDEX idx_admin_audit_action_created ON admin_audit_log(action, created_at DESC);
CREATE INDEX idx_admin_audit_entity ON admin_audit_log(entity_type, entity_id);

-- Нет триггера updated_at (immutable лог)
-- Нет RLS write policy (только INSERT через SECURITY DEFINER функцию)

-- ============================================================================
-- ЧАСТЬ E: ТАБЛИЦА tenant_invitations
-- ============================================================================

CREATE TABLE IF NOT EXISTS tenant_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    token UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    invited_by UUID REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
    accepted_at TIMESTAMP WITH TIME ZONE,
    accepted_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_invitation_status CHECK (status IN ('pending', 'accepted', 'expired', 'cancelled'))
);

COMMENT ON TABLE tenant_invitations IS 'Приглашения сотрудников на точку (онбординг)';
COMMENT ON COLUMN tenant_invitations.id IS 'Уникальный идентификатор приглашения';
COMMENT ON COLUMN tenant_invitations.tenant_id IS 'Тенант';
COMMENT ON COLUMN tenant_invitations.email IS 'Email приглашённого';
COMMENT ON COLUMN tenant_invitations.role_id IS 'Роль';
COMMENT ON COLUMN tenant_invitations.token IS 'Секретный токен для принятия приглашения';
COMMENT ON COLUMN tenant_invitations.invited_by IS 'Кто пригласил';
COMMENT ON COLUMN tenant_invitations.status IS 'Статус: pending, accepted, expired, cancelled';
COMMENT ON COLUMN tenant_invitations.expires_at IS 'Время истечения';
COMMENT ON COLUMN tenant_invitations.accepted_at IS 'Когда принято';
COMMENT ON COLUMN tenant_invitations.accepted_by IS 'Кто принял (user_id)';
COMMENT ON COLUMN tenant_invitations.created_at IS 'Дата создания';

CREATE INDEX idx_tenant_invitations_tenant_status ON tenant_invitations(tenant_id, status);
CREATE INDEX idx_tenant_invitations_token ON tenant_invitations(token);
CREATE INDEX idx_tenant_invitations_email_status ON tenant_invitations(email, status);

-- ============================================================================
-- ЧАСТЬ F: ФУНКЦИИ БИЛЛИНГА И ТЕНАНТОВ
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: create_tenant
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION create_tenant(
    p_name VARCHAR,
    p_slug VARCHAR,
    p_type VARCHAR DEFAULT 'coffee_shop',
    p_country VARCHAR DEFAULT 'RU',
    p_city VARCHAR DEFAULT NULL,
    p_plan_code VARCHAR DEFAULT 'starter',
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_tenant_id UUID;
    v_plan_id UUID;
    v_billing_period VARCHAR(20);
BEGIN
    -- Проверяем уникальность slug
    IF EXISTS (SELECT 1 FROM tenants WHERE slug = p_slug) THEN
        RAISE EXCEPTION 'Slug уже занят: %', p_slug;
    END IF;
    
    -- Находим billing_plan по коду
    SELECT id INTO v_plan_id
    FROM billing_plans
    WHERE code = p_plan_code
      AND is_active = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Тарифный план не найден: %', p_plan_code;
    END IF;
    
    -- Определяем billing_period
    SELECT CASE 
        WHEN price_monthly = 0 THEN 'free'
        ELSE 'monthly'
    END INTO v_billing_period
    FROM billing_plans
    WHERE id = v_plan_id;
    
    -- Создаём тенанта
    INSERT INTO tenants (
        name, slug, type, country, city,
        timezone, currency, is_demo, plan_id
    ) VALUES (
        p_name, p_slug, p_type, p_country, p_city,
        'Europe/Moscow', 'RUB', FALSE, v_plan_id
    )
    RETURNING id INTO v_tenant_id;
    
    -- Создаём подписку
    INSERT INTO billing_subscriptions (
        tenant_id, plan_id, billing_period, status,
        started_at, created_by
    ) VALUES (
        v_tenant_id, v_plan_id, v_billing_period, 'active',
        NOW(), p_created_by
    );
    
    -- Записываем в аудит-лог
    INSERT INTO admin_audit_log (
        user_id, tenant_id, action, entity_type, entity_id,
        new_value
    ) VALUES (
        p_created_by, v_tenant_id, 'tenant.create', 'tenant', v_tenant_id,
        jsonb_build_object('name', p_name, 'slug', p_slug, 'type', p_type)
    );
    
    RETURN v_tenant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: assign_user_to_tenant
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION assign_user_to_tenant(
    p_user_id UUID,
    p_tenant_id UUID,
    p_role_code VARCHAR,
    p_assigned_by UUID
)
RETURNS VOID AS $$
DECLARE
    v_role_id UUID;
BEGIN
    -- Проверяем что пользователь существует
    PERFORM 1 FROM users WHERE id = p_user_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Пользователь не найден: %', p_user_id;
    END IF;
    
    -- Проверяем что тенант существует
    PERFORM 1 FROM tenants WHERE id = p_tenant_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Тенант не найден: %', p_tenant_id;
    END IF;
    
    -- Находим роль по коду
    SELECT id INTO v_role_id
    FROM roles
    WHERE code = p_role_code;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Роль не найдена: %', p_role_code;
    END IF;
    
    -- WHERE NOT EXISTS вместо ON CONFLICT (NULL != NULL в unique)
    INSERT INTO user_roles (user_id, tenant_id, role_id)
    SELECT p_user_id, p_tenant_id, v_role_id
    WHERE NOT EXISTS (
        SELECT 1 FROM user_roles ur
        WHERE ur.user_id = p_user_id
          AND ur.role_id = v_role_id
          AND (ur.tenant_id = p_tenant_id OR (ur.tenant_id IS NULL AND p_tenant_id IS NULL))
    );
    
    -- Записываем в аудит-лог
    INSERT INTO admin_audit_log (
        user_id, tenant_id, action, entity_type, entity_id,
        new_value
    ) VALUES (
        p_assigned_by, p_tenant_id, 'user.role_assign', 'user', p_user_id,
        jsonb_build_object('role_code', p_role_code)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: change_tenant_plan
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION change_tenant_plan(
    p_tenant_id UUID,
    p_new_plan_code VARCHAR,
    p_billing_period VARCHAR,
    p_changed_by UUID
)
RETURNS VOID AS $$
DECLARE
    v_new_plan_id UUID;
    v_old_plan_id UUID;
BEGIN
    -- Находим новый план по коду
    SELECT id INTO v_new_plan_id
    FROM billing_plans
    WHERE code = p_new_plan_code
      AND is_active = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Тарифный план не найден: %', p_new_plan_code;
    END IF;
    
    -- Получаем текущий план
    SELECT plan_id INTO v_old_plan_id
    FROM tenants
    WHERE id = p_tenant_id;
    
    -- Деактивируем текущую активную подписку
    UPDATE billing_subscriptions
    SET status = 'cancelled',
        cancelled_at = NOW(),
        updated_at = NOW()
    WHERE tenant_id = p_tenant_id
      AND status = 'active';
    
    -- Создаём новую подписку
    INSERT INTO billing_subscriptions (
        tenant_id, plan_id, billing_period, status,
        started_at, created_by
    ) VALUES (
        p_tenant_id, v_new_plan_id, p_billing_period, 'active',
        NOW(), p_changed_by
    );
    
    -- Обновляем план у тенанта
    UPDATE tenants
    SET plan_id = v_new_plan_id,
        updated_at = NOW()
    WHERE id = p_tenant_id;
    
    -- Записываем в аудит-лог
    INSERT INTO admin_audit_log (
        user_id, tenant_id, action, entity_type, entity_id,
        old_value, new_value
    ) VALUES (
        p_changed_by, p_tenant_id, 'billing.plan_change', 'tenant', p_tenant_id,
        jsonb_build_object('old_plan_id', v_old_plan_id),
        jsonb_build_object('new_plan_id', v_new_plan_id, 'billing_period', p_billing_period)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: create_invitation
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION create_invitation(
    p_tenant_id UUID,
    p_email VARCHAR,
    p_role_code VARCHAR,
    p_invited_by UUID
)
RETURNS UUID AS $$
DECLARE
    v_role_id UUID;
    v_token UUID;
BEGIN
    -- Находим роль по коду
    SELECT id INTO v_role_id
    FROM roles
    WHERE code = p_role_code;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Роль не найдена: %', p_role_code;
    END IF;
    
    -- Проверяем что нет активного pending приглашения для этого email+tenant
    IF EXISTS (
        SELECT 1 FROM tenant_invitations
        WHERE tenant_id = p_tenant_id
          AND email = p_email
          AND status = 'pending'
          AND expires_at > NOW()
    ) THEN
        RAISE EXCEPTION 'Приглашение уже отправлено на %', p_email;
    END IF;
    
    -- Создаём приглашение
    INSERT INTO tenant_invitations (
        tenant_id, email, role_id, invited_by,
        expires_at
    ) VALUES (
        p_tenant_id, p_email, v_role_id, p_invited_by,
        NOW() + INTERVAL '7 days'
    )
    RETURNING token INTO v_token;
    
    -- Записываем в аудит-лог
    INSERT INTO admin_audit_log (
        user_id, tenant_id, action, entity_type,
        new_value
    ) VALUES (
        p_invited_by, p_tenant_id, 'invitation.create', 'invitation',
        jsonb_build_object('email', p_email, 'role_code', p_role_code)
    );
    
    RETURN v_token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: accept_invitation
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION accept_invitation(
    p_token UUID,
    p_user_id UUID
)
RETURNS TABLE (
    tenant_id UUID,
    role_code VARCHAR
) AS $$
DECLARE
    v_invitation RECORD;
BEGIN
    -- Находим приглашение с блокировкой
    SELECT * INTO v_invitation
    FROM tenant_invitations
    WHERE token = p_token
      AND status = 'pending'
      AND expires_at > NOW()
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Приглашение не найдено или истекло';
    END IF;
    
    -- Назначаем роль пользователю
    INSERT INTO user_roles (user_id, tenant_id, role_id)
    VALUES (p_user_id, v_invitation.tenant_id, v_invitation.role_id)
    ON CONFLICT (user_id, tenant_id, role_id) DO NOTHING;
    
    -- Обновляем приглашение
    UPDATE tenant_invitations
    SET status = 'accepted',
        accepted_at = NOW(),
        accepted_by = p_user_id
    WHERE id = v_invitation.id;
    
    -- Возвращаем tenant_id и role_code
    RETURN QUERY
    SELECT 
        v_invitation.tenant_id,
        r.code
    FROM roles r
    WHERE r.id = v_invitation.role_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: log_admin_action
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION log_admin_action(
    p_user_id UUID,
    p_tenant_id UUID,
    p_action VARCHAR,
    p_entity_type VARCHAR DEFAULT NULL,
    p_entity_id UUID DEFAULT NULL,
    p_old_value JSONB DEFAULT NULL,
    p_new_value JSONB DEFAULT NULL,
    p_ip_address VARCHAR DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO admin_audit_log (
        user_id, tenant_id, action, entity_type, entity_id,
        old_value, new_value, ip_address
    ) VALUES (
        p_user_id, p_tenant_id, p_action, p_entity_type, p_entity_id,
        p_old_value, p_new_value, p_ip_address
    )
    RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ЧАСТЬ G: ФУНКЦИИ ГЛОБАЛЬНОЙ АНАЛИТИКИ
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: get_network_summary
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_network_summary(
    p_from TIMESTAMP WITH TIME ZONE,
    p_to TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
    total_tenants INTEGER,
    total_orders INTEGER,
    total_revenue DECIMAL(10,2),
    avg_revenue_per_tenant DECIMAL(10,2),
    total_customers INTEGER,
    total_loyalty_points INTEGER,
    top_tenant_id UUID,
    top_tenant_name VARCHAR(100),
    top_tenant_revenue DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (
            SELECT COUNT(*)
            FROM tenants t
            WHERE t.type = 'coffee_shop'
              AND t.status = 'active'
        )::INTEGER AS total_tenants,
        
        (
            SELECT COUNT(*)
            FROM orders o
            JOIN tenants t ON o.tenant_id = t.id
            WHERE t.type = 'coffee_shop'
              AND t.status = 'active'
              AND o.created_at >= p_from
              AND o.created_at <= p_to
        )::INTEGER AS total_orders,
        
        (
            SELECT COALESCE(SUM(p.amount), 0)
            FROM payments p
            JOIN orders o ON p.order_id = o.id
            JOIN tenants t ON o.tenant_id = t.id
            WHERE t.type = 'coffee_shop'
              AND t.status = 'active'
              AND p.status = 'paid'
              AND o.created_at >= p_from
              AND o.created_at <= p_to
        )::DECIMAL(10,2) AS total_revenue,
        
        (
            SELECT COALESCE(SUM(p.amount), 0) / NULLIF(COUNT(DISTINCT t.id), 0)
            FROM payments p
            JOIN orders o ON p.order_id = o.id
            JOIN tenants t ON o.tenant_id = t.id
            WHERE t.type = 'coffee_shop'
              AND t.status = 'active'
              AND p.status = 'paid'
              AND o.created_at >= p_from
              AND o.created_at <= p_to
        )::DECIMAL(10,2) AS avg_revenue_per_tenant,
        
        (
            SELECT COUNT(DISTINCT o.customer_id)
            FROM orders o
            JOIN tenants t ON o.tenant_id = t.id
            WHERE t.type = 'coffee_shop'
              AND t.status = 'active'
              AND o.customer_id IS NOT NULL
              AND o.created_at >= p_from
              AND o.created_at <= p_to
        )::INTEGER AS total_customers,
        
        (
            SELECT COALESCE(SUM(la.balance), 0)
            FROM loyalty_accounts la
        )::INTEGER AS total_loyalty_points,
        
        (
            SELECT t.id
            FROM tenants t
            JOIN orders o ON t.id = o.tenant_id
            JOIN payments p ON p.order_id = o.id
            WHERE t.type = 'coffee_shop'
              AND t.status = 'active'
              AND p.status = 'paid'
              AND o.created_at >= p_from
              AND o.created_at <= p_to
            GROUP BY t.id
            ORDER BY SUM(p.amount) DESC
            LIMIT 1
        ) AS top_tenant_id,
        
        (
            SELECT t.name
            FROM tenants t
            JOIN orders o ON t.id = o.tenant_id
            JOIN payments p ON p.order_id = o.id
            WHERE t.type = 'coffee_shop'
              AND t.status = 'active'
              AND p.status = 'paid'
              AND o.created_at >= p_from
              AND o.created_at <= p_to
            GROUP BY t.id, t.name
            ORDER BY SUM(p.amount) DESC
            LIMIT 1
        ) AS top_tenant_name,
        
        (
            SELECT SUM(p.amount)
            FROM tenants t
            JOIN orders o ON t.id = o.tenant_id
            JOIN payments p ON p.order_id = o.id
            WHERE t.type = 'coffee_shop'
              AND t.status = 'active'
              AND p.status = 'paid'
              AND o.created_at >= p_from
              AND o.created_at <= p_to
            GROUP BY t.id
            ORDER BY SUM(p.amount) DESC
            LIMIT 1
        ) AS top_tenant_revenue;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ----------------------------------------------------------------------------
-- ФУНКЦИЯ: get_tenant_comparison
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_tenant_comparison(
    p_from TIMESTAMP WITH TIME ZONE,
    p_to TIMESTAMP WITH TIME ZONE,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    tenant_id UUID,
    tenant_name VARCHAR(100),
    city VARCHAR(100),
    orders_count INTEGER,
    revenue DECIMAL(10,2),
    avg_order DECIMAL(10,2),
    new_customers INTEGER,
    revenue_rank INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH tenant_revenue AS (
        -- Сначала считаем выручку для каждой точки
        SELECT 
            t.id AS tenant_id,
            COALESCE(SUM(p.amount), 0) AS revenue
        FROM tenants t
        LEFT JOIN orders o ON t.id = o.tenant_id
            AND o.created_at >= p_from
            AND o.created_at <= p_to
        LEFT JOIN payments p ON p.order_id = o.id
            AND p.status = 'paid'
        WHERE t.type = 'coffee_shop'
          AND t.status = 'active'
        GROUP BY t.id
    ),
    tenant_stats AS (
        -- Потом считаем остальную статистику
        SELECT 
            t.id AS tenant_id,
            t.name AS tenant_name,
            t.city,
            (
                SELECT COUNT(*)
                FROM orders o
                WHERE o.tenant_id = t.id
                  AND o.created_at >= p_from
                  AND o.created_at <= p_to
            )::INTEGER AS orders_count,
            tr.revenue,
            (
                SELECT COALESCE(AVG(o.final_amount), 0)
                FROM orders o
                WHERE o.tenant_id = t.id
                  AND o.created_at >= p_from
                  AND o.created_at <= p_to
            )::DECIMAL(10,2) AS avg_order,
            (
                SELECT COUNT(DISTINCT o.customer_id)
                FROM orders o
                WHERE o.tenant_id = t.id
                  AND o.customer_id IS NOT NULL
                  AND o.created_at >= p_from
                  AND o.created_at <= p_to
                  AND NOT EXISTS (
                      SELECT 1 FROM orders o2
                      WHERE o2.customer_id = o.customer_id
                        AND o2.created_at < p_from
                  )
            )::INTEGER AS new_customers
        FROM tenants t
        JOIN tenant_revenue tr ON t.id = tr.tenant_id
        WHERE t.type = 'coffee_shop'
          AND t.status = 'active'
    )
    -- Применяем RANK() к готовым данным
    SELECT 
        ts.tenant_id,
        ts.tenant_name,
        ts.city,
        ts.orders_count,
        ts.revenue,
        ts.avg_order,
        ts.new_customers,
        RANK() OVER (ORDER BY ts.revenue DESC)::INTEGER AS revenue_rank
    FROM tenant_stats ts
    ORDER BY ts.revenue DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- ЧАСТЬ H: VIEWS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- VIEW: v_tenants_overview
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_tenants_overview AS
SELECT 
    t.id AS tenant_id,
    t.name,
    t.slug,
    t.type,
    t.country,
    t.city,
    t.status,
    t.is_demo,
    bp.code AS plan_code,
    bp.name AS plan_name,
    bs.status AS subscription_status,
    bs.expires_at AS subscription_expires_at,
    (
        SELECT COUNT(*)
        FROM devices d
        WHERE d.tenant_id = t.id
          AND d.is_active = TRUE
    )::INTEGER AS devices_count,
    (
        SELECT COUNT(DISTINCT ur.user_id)
        FROM user_roles ur
        WHERE ur.tenant_id = t.id
    )::INTEGER AS staff_count,
    t.created_at
FROM tenants t
LEFT JOIN billing_plans bp ON t.plan_id = bp.id
LEFT JOIN billing_subscriptions bs ON t.id = bs.tenant_id AND bs.status = 'active'
ORDER BY t.created_at DESC;

COMMENT ON VIEW v_tenants_overview IS 'Обзор всех точек для admin panel УК';

-- ----------------------------------------------------------------------------
-- VIEW: v_billing_overview
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_billing_overview AS
SELECT 
    t.id AS tenant_id,
    t.name AS tenant_name,
    t.type AS tenant_type,
    bp.code AS plan_code,
    bp.name AS plan_name,
    bp.price_monthly,
    bs.billing_period,
    bs.status AS subscription_status,
    bs.started_at,
    bs.expires_at,
    EXTRACT(DAY FROM (bs.expires_at - NOW()))::INTEGER AS days_until_expiry,
    (bs.expires_at < NOW() AND bs.status = 'active') AS is_overdue
FROM tenants t
JOIN billing_subscriptions bs ON t.id = bs.tenant_id AND bs.status = 'active'
JOIN billing_plans bp ON bs.plan_id = bp.id
ORDER BY bs.expires_at ASC;

COMMENT ON VIEW v_billing_overview IS 'Биллинг по всем точкам';

-- ----------------------------------------------------------------------------
-- VIEW: v_network_stats_today
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_network_stats_today AS
SELECT 
    t.id AS tenant_id,
    t.name AS tenant_name,
    (
        SELECT COUNT(*)
        FROM orders o
        WHERE o.tenant_id = t.id
          AND o.created_at >= CURRENT_DATE
    )::INTEGER AS orders_today,
    (
        SELECT COALESCE(SUM(p.amount), 0)
        FROM orders o
        JOIN payments p ON p.order_id = o.id
        WHERE o.tenant_id = t.id
          AND p.status = 'paid'
          AND o.created_at >= CURRENT_DATE
    )::DECIMAL(10,2) AS revenue_today,
    (
        SELECT COALESCE(AVG(o.final_amount), 0)
        FROM orders o
        WHERE o.tenant_id = t.id
          AND o.created_at >= CURRENT_DATE
    )::DECIMAL(10,2) AS avg_order_today,
    (
        SELECT COUNT(*)
        FROM shifts s
        WHERE s.tenant_id = t.id
          AND s.status = 'open'
    )::INTEGER AS active_shifts,
    (
        SELECT COUNT(*)
        FROM orders o
        WHERE o.tenant_id = t.id
          AND o.status = 'ready'
    )::INTEGER AS ready_orders
FROM tenants t
WHERE t.type = 'coffee_shop'
  AND t.status = 'active'
ORDER BY revenue_today DESC;

COMMENT ON VIEW v_network_stats_today IS 'Статистика по сети за сегодня (живой дашборд УК)';

-- ============================================================================
-- ЧАСТЬ I: ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE billing_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_invitations ENABLE ROW LEVEL SECURITY;

-- billing_plans: read — все авторизованные
CREATE POLICY rls_billing_plans_read ON billing_plans
    FOR SELECT
    USING (TRUE);

-- billing_plans: write — ук_global_admin/ук_billing_admin
CREATE POLICY rls_billing_plans_write ON billing_plans
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_billing_admin')
        )
    );

-- billing_subscriptions: read — УК + office_manager своего тенанта
CREATE POLICY rls_billing_subscriptions_read ON billing_subscriptions
    FOR SELECT
    USING (
        (
            tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
            AND EXISTS (
                SELECT 1 FROM user_roles ur
                JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                AND r.code IN ('office_manager')
            )
        )
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_billing_admin', 'ук_country_manager')
        )
    );

-- billing_subscriptions: write — только через SECURITY DEFINER функции

-- admin_audit_log: read — УК + office_manager своего тенанта
CREATE POLICY rls_admin_audit_log_read ON admin_audit_log
    FOR SELECT
    USING (
        (
            tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
            AND EXISTS (
                SELECT 1 FROM user_roles ur
                JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                AND r.code IN ('office_manager')
            )
        )
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager')
        )
    );

-- admin_audit_log: write — только через log_admin_action функцию (нет write policy)

-- tenant_invitations: read — office_manager/shift_manager своего тенанта + УК
CREATE POLICY rls_tenant_invitations_read ON tenant_invitations
    FOR SELECT
    USING (
        (
            tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
            AND EXISTS (
                SELECT 1 FROM user_roles ur
                JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                AND r.code IN ('office_manager', 'shift_manager')
            )
        )
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager')
        )
    );

-- tenant_invitations: write — office_manager своего тенанта + УК
CREATE POLICY rls_tenant_invitations_write ON tenant_invitations
    FOR ALL
    USING (
        (
            tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
            AND EXISTS (
                SELECT 1 FROM user_roles ur
                JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
                AND r.code IN ('office_manager')
            )
        )
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager')
        )
    );

-- ============================================================================
-- ЧАСТЬ J: SEED DATA
-- ============================================================================

BEGIN;

SET LOCAL row_security = off;

-- 1. Создаём тарифные планы
INSERT INTO billing_plans (code, name, description, price_monthly, price_yearly, max_devices, max_products, max_staff, features, sort_order)
VALUES 
    ('free', 'Бесплатный', 'Базовый план для тестирования', 0, NULL, 2, 20, 3, 
     '{"kiosk": false, "mobile_app": false, "loyalty": false}'::JSONB, 1),
    ('starter', 'Стартер', 'Для небольших кофеен', 2990, 29900, 5, 100, 10,
     '{"kiosk": true, "mobile_app": true, "loyalty": false}'::JSONB, 2),
    ('pro', 'Про', 'Полный функционал для сети', 5990, 59900, NULL, NULL, NULL,
     '{"kiosk": true, "mobile_app": true, "loyalty": true, "production": true, "analytics": true}'::JSONB, 3)
ON CONFLICT (code) DO NOTHING;

-- 2. Создаём вторую тестовую точку
INSERT INTO tenants (id, name, slug, type, status, country, city, timezone, currency, is_demo)
VALUES (
    '00000000-0000-0000-0000-000000000003',
    'Кофейня на Ленина',
    'coffee-lenina',
    'coffee_shop',
    'active',
    'RU',
    'Москва',
    'Europe/Moscow',
    'RUB',
    TRUE
)
ON CONFLICT (id) DO NOTHING;

-- 3. Обновляем первую точку
UPDATE tenants 
SET type = 'coffee_shop', 
    city = 'Москва',
    timezone = 'Europe/Moscow',
    currency = 'RUB',
    is_demo = TRUE
WHERE id = '00000000-0000-0000-0000-000000000001';

-- 4. Обновляем цех
UPDATE tenants 
SET type = 'production_kitchen',
    city = 'Москва',
    timezone = 'Europe/Moscow',
    currency = 'RUB'
WHERE id = '00000000-0000-0000-0000-000000000002';

-- 5. Назначаем plan_id для всех трёх тенантов
UPDATE tenants
SET plan_id = (SELECT id FROM billing_plans WHERE code = 'pro')
WHERE id IN ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002');

UPDATE tenants
SET plan_id = (SELECT id FROM billing_plans WHERE code = 'starter')
WHERE id = '00000000-0000-0000-0000-000000000003';

-- 6. Создаём billing_subscriptions для всех тенантов
INSERT INTO billing_subscriptions (tenant_id, plan_id, billing_period, status, started_at, expires_at)
SELECT 
    t.id,
    t.plan_id,
    CASE WHEN bp.price_monthly = 0 THEN 'free' ELSE 'monthly' END,
    'active',
    NOW(),
    NOW() + INTERVAL '30 days'
FROM tenants t
JOIN billing_plans bp ON t.plan_id = bp.id
WHERE t.id IN ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000003')
  AND NOT EXISTS (
      SELECT 1 FROM billing_subscriptions bs
      WHERE bs.tenant_id = t.id AND bs.status = 'active'
  );

-- 7. Создаём тестового пользователя УК
INSERT INTO users (email, first_name, last_name, phone, is_active)
VALUES (
    'admin@ук.ru',
    'Главный',
    'Администратор',
    '+79000000099',
    TRUE
)
ON CONFLICT (email) DO NOTHING;

-- 8. Назначаем роль ук_global_admin тестовому пользователю
-- ИСПРАВЛЕНИЕ: Убрано дублирующееся условие (ur.tenant_id IS NULL OR ur.tenant_id IS NULL)
INSERT INTO user_roles (user_id, role_id, tenant_id)
SELECT 
    u.id,
    r.id,
    NULL  -- tenant_id NULL для УК ролей
FROM users u, roles r
WHERE u.email = 'admin@ук.ru'
  AND r.code = 'ук_global_admin'
  AND NOT EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = u.id
        AND ur.role_id = r.id
        AND ur.tenant_id IS NULL
  );

COMMIT;

-- ============================================================================
-- КОНЕЦ МИГРАЦИЙ ЭТАПА 12
-- ============================================================================

/*
================================================================================
ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ

1. КАК СОЗДАТЬ НОВУЮ ТОЧКУ
   SELECT create_tenant('Кофейня на Арбате', 'coffee-arbat', 'coffee_shop', 'RU', 'Москва', 'starter', 'user-uuid');

2. КАК НАЗНАЧИТЬ ПОЛЬЗОВАТЕЛЯ НА ТОЧКУ
   SELECT assign_user_to_tenant('user-uuid', 'tenant-uuid', 'office_manager', 'admin-uuid');

3. КАК СМЕНИТЬ ТАРИФНЫЙ ПЛАН
   SELECT change_tenant_plan('tenant-uuid', 'pro', 'monthly', 'admin-uuid');

4. КАК СОЗДАТЬ ПРИГЛАШЕНИЕ
   SELECT create_invitation('tenant-uuid', 'newuser@example.com', 'barista', 'admin-uuid');

5. КАК ПРИНЯТЬ ПРИГЛАШЕНИЕ
   SELECT * FROM accept_invitation('invitation-token', 'user-uuid');

6. КАК ЗАПИСАТЬ ДЕЙСТВИЕ В АУДИТ
   SELECT log_admin_action('user-uuid', 'tenant-uuid', 'product.disable', 'product', 'product-uuid');

7. КАК ПОЛУЧИТЬ СВОДКУ ПО СЕТИ
   SELECT * FROM get_network_summary('2025-01-01', '2025-01-31');

8. КАК ПОЛУЧИТЬ СРАВНЕНИЕ ТОЧЕК
   SELECT * FROM get_tenant_comparison('2025-01-01', '2025-01-31', 10);

================================================================================
ИСПРАВЛЕНИЯ В ЭТОЙ ВЕРСИИ (1.2)

1. ✅ SEED шаг 8: Убрано дублирующееся условие в WHERE NOT EXISTS
   - Было: AND (ur.tenant_id IS NULL OR ur.tenant_id IS NULL)
   - Стало: AND ur.tenant_id IS NULL
   - Косметическое исправление опечатки при копировании

================================================================================
АРХИТЕКТУРНЫЕ ЗАМЕЧАНИЯ

1. ✅ УК = надтенантная структура (роли без tenant_id или с NULL tenant_id)
2. ✅ billing_plans: price_monthly, price_yearly, max_* ограничения
3. ✅ billing_subscriptions: ON DELETE RESTRICT для plan_id
4. ✅ admin_audit_log: immutable лог (нет updated_at, нет write RLS policy)
5. ✅ tenant_invitations: token для принятия приглашения, expires_at = 7 дней
6. ✅ create_tenant: всегда создаёт billing_subscription
7. ✅ accept_invitation: FOR UPDATE для защиты от race condition
8. ✅ create_invitation: проверка дублирования pending приглашений
9. ✅ get_network_summary/get_tenant_comparison: только coffee_shop + status='active' + payments.status='paid'
10. ✅ DECIMAL(10,2) для денежных полей
11. ✅ CHECK constraints на все enum-поля
12. ✅ SECURITY DEFINER на всех функциях
13. ✅ SEED DATA: 3 тарифных плана, 2 точки + цех, тестовый пользователь УК

================================================================================
*/
```
apps-fileview.texmex_20260501.02_p0
ядро 12 этап.txt
ядро 12 этап.txt. На экране.