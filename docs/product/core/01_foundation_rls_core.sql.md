
```sql
-- ============================================================================
-- SQL МИГРАЦИИ ДЛЯ СИСТЕМЫ КОФЕЕН (POSTGRESQL)
-- Версия 3.1 - Исправлены SET LOCAL и RLS политика payments
-- ============================================================================

-- ============================================================================
-- ЭТАП 0: ФУНДАМЕНТ
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ENUM TYPES (СТАБИЛЬНЫЕ - не будут расширяться)
-- ----------------------------------------------------------------------------

DO $$ BEGIN
    CREATE TYPE tenant_type AS ENUM ('sales_point', 'production_kitchen');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE tenant_status AS ENUM ('active', 'warning', 'suspended', 'blocked', 'frozen');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE user_status AS ENUM ('active', 'blocked');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE ingredient_unit AS ENUM ('g', 'ml', 'pcs');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE ingredient_type AS ENUM ('raw_material', 'semi_finished', 'packaging');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE feature_action AS ENUM ('enabled', 'disabled');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE order_status AS ENUM ('pending_payment', 'accepted', 'preparing', 'ready', 'issued', 'closed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE order_source AS ENUM ('kiosk', 'app', 'manual');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE status_change_source AS ENUM ('system', 'barista', 'shift_manager', 'payment_callback', 'customer');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_method AS ENUM ('card', 'cash', 'sbp', 'apple_pay', 'google_pay', 'internal_balance', 'mixed');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM ('pending', 'processing', 'succeeded', 'failed', 'refunded', 'partially_refunded', 'requires_review');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status_source AS ENUM ('callback', 'polling', 'manual');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE refund_status AS ENUM ('pending', 'succeeded', 'failed');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE receipt_type AS ENUM ('payment', 'refund');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE receipt_status AS ENUM ('pending', 'sent', 'confirmed', 'failed');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE cash_shift_status AS ENUM ('open', 'closed');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ----------------------------------------------------------------------------
-- TABLE: tenants
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    type tenant_type NOT NULL,
    status tenant_status NOT NULL DEFAULT 'active',
    country VARCHAR(2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'RUB',
    timezone VARCHAR(50) NOT NULL DEFAULT 'Europe/Moscow',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE tenants IS 'Тенанты системы: точки продаж и заготовочные цеха';
COMMENT ON COLUMN tenants.id IS 'Уникальный идентификатор тенанта';
COMMENT ON COLUMN tenants.name IS 'Название точки/цеха';
COMMENT ON COLUMN tenants.type IS 'Тип тенанта: точка продаж или производственный цех';
COMMENT ON COLUMN tenants.status IS 'Статус тенанта для контроля доступа';
COMMENT ON COLUMN tenants.country IS 'Код страны (ISO 3166-1 alpha-2)';
COMMENT ON COLUMN tenants.currency IS 'Код валюты (ISO 4217)';
COMMENT ON COLUMN tenants.timezone IS 'Часовой пояс для локализации времени';

CREATE INDEX idx_tenants_type ON tenants(type);
CREATE INDEX idx_tenants_status ON tenants(status);
CREATE INDEX idx_tenants_country ON tenants(country);

-- ----------------------------------------------------------------------------
-- TABLE: roles (глобальная таблица)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT
);

COMMENT ON TABLE roles IS 'Роли пользователей системы (глобальная таблица)';
COMMENT ON COLUMN roles.code IS 'Уникальный код роли для JWT и проверок';
COMMENT ON COLUMN roles.name IS 'Человекочитаемое название роли';
COMMENT ON COLUMN roles.description IS 'Описание полномочий роли';

INSERT INTO roles (code, name, description) VALUES
('barista', 'Бариста', 'Только табло заказов своей точки'),
('shift_manager', 'Менеджер смены', 'Оперативное управление сменой'),
('office_manager', 'Офис-менеджер', 'Полный доступ внутри одной точки'),
('franchise_manager', 'Франшиз-менеджер', 'Все свои точки, без глубины'),
('prep_kitchen_manager', 'Управляющий цеха', 'Управляющий заготовочного цеха'),
('prep_kitchen_worker', 'Сотрудник цеха', 'Сотрудник заготовочного цеха'),
('ук_global_admin', 'Глобальный админ УК', 'Полный доступ ко всей системе'),
('ук_country_manager', 'Менеджер страны УК', 'Управление по странам'),
('ук_billing_admin', 'Биллинг админ УК', 'Управление финансами и биллингом')
ON CONFLICT (code) DO NOTHING;

CREATE INDEX idx_roles_code ON roles(code);

-- ----------------------------------------------------------------------------
-- TABLE: users
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE SET NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    status user_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_users_contact CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

COMMENT ON TABLE users IS 'Пользователи системы';
COMMENT ON COLUMN users.id IS 'Уникальный идентификатор пользователя';
COMMENT ON COLUMN users.tenant_id IS 'Привязка к тенанту (NULL для сотрудников УК)';
COMMENT ON COLUMN users.email IS 'Уникальный email для входа (nullable, можно использовать phone)';
COMMENT ON COLUMN users.phone IS 'Номер телефона для входа (если нет email)';
COMMENT ON COLUMN users.name IS 'ФИО пользователя';
COMMENT ON COLUMN users.password_hash IS 'Хеш пароля (bcrypt с cost >= 12)';
COMMENT ON COLUMN users.status IS 'Статус учётной записи';

CREATE INDEX idx_users_tenant_id ON users(tenant_id);
CREATE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_phone ON users(phone) WHERE phone IS NOT NULL;
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_tenant_status ON users(tenant_id, status);

-- ----------------------------------------------------------------------------
-- TABLE: user_roles
-- Уникальность через индекс с COALESCE для обработки NULL tenant_id
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE user_roles IS 'Связь пользователей с ролями и тенантами';
COMMENT ON COLUMN user_roles.user_id IS 'Ссылка на пользователя';
COMMENT ON COLUMN user_roles.role_id IS 'Ссылка на роль';
COMMENT ON COLUMN user_roles.tenant_id IS 'Тенант для которого действует роль (NULL для ролей УК)';

-- Уникальный индекс с COALESCE для корректной работы с NULL tenant_id
CREATE UNIQUE INDEX idx_user_roles_unique 
    ON user_roles(user_id, role_id, COALESCE(tenant_id, '00000000-0000-0000-0000-000000000000'::UUID));

CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);
CREATE INDEX idx_user_roles_tenant_id ON user_roles(tenant_id);
CREATE INDEX idx_user_roles_user_tenant ON user_roles(user_id, tenant_id);

-- ----------------------------------------------------------------------------
-- TABLE: sessions
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES tenants(id) ON DELETE SET NULL,
    role_code VARCHAR(50) NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMP WITH TIME ZONE
);

COMMENT ON TABLE sessions IS 'Активные сессии пользователей';
COMMENT ON COLUMN sessions.id IS 'Уникальный идентификатор сессии';
COMMENT ON COLUMN sessions.user_id IS 'Ссылка на пользователя';
COMMENT ON COLUMN sessions.tenant_id IS 'Тенант сессии';
COMMENT ON COLUMN sessions.role_code IS 'Код активной роли в сессии';
COMMENT ON COLUMN sessions.token_hash IS 'Хеш JWT токена для поиска и отзыва';
COMMENT ON COLUMN sessions.expires_at IS 'Время истечения сессии';
COMMENT ON COLUMN sessions.revoked_at IS 'Время отзыва сессии (NULL = активна)';

CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_tenant_id ON sessions(tenant_id);
CREATE INDEX idx_sessions_token_hash ON sessions(token_hash);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX idx_sessions_active ON sessions(user_id, revoked_at) WHERE revoked_at IS NULL;

-- ----------------------------------------------------------------------------
-- TABLE: ingredients (глобальная таблица)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    unit ingredient_unit NOT NULL,
    type ingredient_type NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE ingredients IS 'Справочник ингредиентов (глобальная таблица, единая для всей сети)';
COMMENT ON COLUMN ingredients.id IS 'Core UUID единый для всей сети';
COMMENT ON COLUMN ingredients.name IS 'Название ингредиента';
COMMENT ON COLUMN ingredients.unit IS 'Единица измерения';
COMMENT ON COLUMN ingredients.type IS 'Тип: сырьё, полуфабрикат, упаковка';
COMMENT ON COLUMN ingredients.is_active IS 'Флаг активности ингредиента';

CREATE INDEX idx_ingredients_type ON ingredients(type);
CREATE INDEX idx_ingredients_active ON ingredients(is_active);
CREATE INDEX idx_ingredients_name ON ingredients(name);

-- ----------------------------------------------------------------------------
-- TABLE: feature_flags
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS feature_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    module VARCHAR(100) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    enabled_at TIMESTAMP WITH TIME ZONE,
    enabled_by UUID REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE(tenant_id, module)
);

COMMENT ON TABLE feature_flags IS 'Флаги функциональности по тенантам';
COMMENT ON COLUMN feature_flags.tenant_id IS 'Тенант для которого настроен флаг';
COMMENT ON COLUMN feature_flags.module IS 'Модуль системы (app, kiosk, smart_locker, prep_kitchen, push, qr_status)';
COMMENT ON COLUMN feature_flags.enabled IS 'Статус флага';
COMMENT ON COLUMN feature_flags.enabled_at IS 'Время включения';
COMMENT ON COLUMN feature_flags.enabled_by IS 'Пользователь включивший флаг';

CREATE INDEX idx_feature_flags_tenant_id ON feature_flags(tenant_id);
CREATE INDEX idx_feature_flags_module ON feature_flags(module);
CREATE INDEX idx_feature_flags_enabled ON feature_flags(enabled);

-- ----------------------------------------------------------------------------
-- TABLE: feature_flags_log
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS feature_flags_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    module VARCHAR(100) NOT NULL,
    action feature_action NOT NULL,
    changed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE feature_flags_log IS 'Лог изменений feature flags';
COMMENT ON COLUMN feature_flags_log.tenant_id IS 'Тенант';
COMMENT ON COLUMN feature_flags_log.module IS 'Модуль';
COMMENT ON COLUMN feature_flags_log.action IS 'Действие: включение/выключение';
COMMENT ON COLUMN feature_flags_log.changed_by IS 'Пользователь изменивший флаг';
COMMENT ON COLUMN feature_flags_log.reason IS 'Причина изменения';

CREATE INDEX idx_feature_flags_log_tenant_id ON feature_flags_log(tenant_id);
CREATE INDEX idx_feature_flags_log_module ON feature_flags_log(module);
CREATE INDEX idx_feature_flags_log_created_at ON feature_flags_log(created_at);

-- ============================================================================
-- ЭТАП 1: ЗАКАЗЫ И СТАТУСНАЯ МОДЕЛЬ
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLE: orders
-- order_sequence BIGSERIAL для автоинкремента
-- order_number заполняется триггером автоматически
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    order_number VARCHAR(20) NOT NULL,
    order_sequence BIGSERIAL,
    source order_source NOT NULL,
    customer_id UUID,
    customer_name VARCHAR(255),
    status order_status NOT NULL DEFAULT 'pending_payment',
    cancel_reason TEXT,
    cancel_stage order_status,
    total_amount DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    final_amount DECIMAL(10,2) NOT NULL,
    promo_code_id UUID,
    locker_cell VARCHAR(10),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_order_number_per_tenant UNIQUE (tenant_id, order_number),
    CONSTRAINT chk_order_amounts CHECK (
        total_amount > 0 AND
        discount_amount >= 0 AND
        final_amount >= 0 AND
        final_amount = total_amount - discount_amount
    )
);

COMMENT ON TABLE orders IS 'Заказы клиентов';
COMMENT ON COLUMN orders.id IS 'Уникальный идентификатор заказа';
COMMENT ON COLUMN orders.tenant_id IS 'Точка продаж';
COMMENT ON COLUMN orders.order_number IS 'Читаемый номер заказа - уникален в пределах тенанта (формат #YYYYMM-####)';
COMMENT ON COLUMN orders.order_sequence IS 'Автоинкремент для генерации номера заказа';
COMMENT ON COLUMN orders.source IS 'Источник заказа: киоск, приложение, вручную';
COMMENT ON COLUMN orders.customer_id IS 'ID клиента в облаке УК (без FK)';
COMMENT ON COLUMN orders.customer_name IS 'Снапшот имени для чека';
COMMENT ON COLUMN orders.status IS 'Текущий статус заказа';
COMMENT ON COLUMN orders.cancel_reason IS 'Причина отмены';
COMMENT ON COLUMN orders.cancel_stage IS 'Этап на котором отменён';
COMMENT ON COLUMN orders.total_amount IS 'Сумма до скидок';
COMMENT ON COLUMN orders.discount_amount IS 'Сумма скидки';
COMMENT ON COLUMN orders.final_amount IS 'Итоговая сумма к оплате';
COMMENT ON COLUMN orders.promo_code_id IS 'ID промокода в облаке УК (без FK)';
COMMENT ON COLUMN orders.locker_cell IS 'Номер ячейки локера для выдачи';

CREATE INDEX idx_orders_tenant_id ON orders(tenant_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_tenant_status ON orders(tenant_id, status);
CREATE INDEX idx_orders_tenant_created ON orders(tenant_id, created_at DESC);
CREATE INDEX idx_orders_number ON orders(order_number);

-- ----------------------------------------------------------------------------
-- TABLE: order_items
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    modifier_options JSONB,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_items_prices CHECK (unit_price >= 0 AND total_price >= 0)
);

COMMENT ON TABLE order_items IS 'Позиции заказа';
COMMENT ON COLUMN order_items.id IS 'Уникальный идентификатор позиции';
COMMENT ON COLUMN order_items.order_id IS 'Ссылка на заказ';
COMMENT ON COLUMN order_items.product_id IS 'ID продукта (без FK — может измениться)';
COMMENT ON COLUMN order_items.product_name IS 'Снапшот названия на момент заказа';
COMMENT ON COLUMN order_items.modifier_options IS 'Опции модификаторов (размер, молоко и т.д.)';
COMMENT ON COLUMN order_items.quantity IS 'Количество';
COMMENT ON COLUMN order_items.unit_price IS 'Снапшот цены за единицу';
COMMENT ON COLUMN order_items.total_price IS 'Сумма по позиции';

CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- ----------------------------------------------------------------------------
-- TABLE: order_status_log
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS order_status_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status_from order_status,
    status_to order_status NOT NULL,
    changed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    source status_change_source NOT NULL,
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE order_status_log IS 'Лог изменений статуса заказа';
COMMENT ON COLUMN order_status_log.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN order_status_log.order_id IS 'Ссылка на заказ';
COMMENT ON COLUMN order_status_log.status_from IS 'Предыдущий статус (NULL для первого)';
COMMENT ON COLUMN order_status_log.status_to IS 'Новый статус';
COMMENT ON COLUMN order_status_log.changed_by IS 'Пользователь изменивший статус';
COMMENT ON COLUMN order_status_log.source IS 'Источник изменения';
COMMENT ON COLUMN order_status_log.comment IS 'Комментарий к изменению';

CREATE INDEX idx_order_status_log_order_id ON order_status_log(order_id);
CREATE INDEX idx_order_status_log_created_at ON order_status_log(created_at);
CREATE INDEX idx_order_status_log_status_to ON order_status_log(status_to);

-- ============================================================================
-- ЭТАП 2: ОПЛАТА И ФИСКАЛИЗАЦИЯ
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLE: payments
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    method payment_method NOT NULL,
    status payment_status NOT NULL DEFAULT 'pending',
    provider VARCHAR(50) NOT NULL,
    provider_payment_id VARCHAR(255),
    provider_response JSONB,
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_payments_amount CHECK (amount > 0)
);

COMMENT ON TABLE payments IS 'Платежи по заказам';
COMMENT ON COLUMN payments.id IS 'Уникальный идентификатор платежа';
COMMENT ON COLUMN payments.tenant_id IS 'Тенант';
COMMENT ON COLUMN payments.order_id IS 'Ссылка на заказ';
COMMENT ON COLUMN payments.amount IS 'Сумма платежа';
COMMENT ON COLUMN payments.method IS 'Метод оплаты';
COMMENT ON COLUMN payments.status IS 'Статус платежа';
COMMENT ON COLUMN payments.provider IS 'Платёжный провайдер (yukassa, tinkoff, stripe, kaspi_pay...)';
COMMENT ON COLUMN payments.provider_payment_id IS 'ID платежа у провайдера';
COMMENT ON COLUMN payments.provider_response IS 'Сырой ответ провайдера для отладки';
COMMENT ON COLUMN payments.paid_at IS 'Время успешной оплаты';

CREATE INDEX idx_payments_tenant_id ON payments(tenant_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_provider ON payments(provider);
CREATE INDEX idx_payments_provider_id ON payments(provider_payment_id);
CREATE INDEX idx_payments_created_at ON payments(created_at);
CREATE INDEX idx_payments_tenant_status ON payments(tenant_id, status);

-- ----------------------------------------------------------------------------
-- TABLE: payment_status_log
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS payment_status_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    status_from payment_status,
    status_to payment_status NOT NULL,
    source payment_status_source NOT NULL,
    raw_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE payment_status_log IS 'Лог изменений статуса платежа';
COMMENT ON COLUMN payment_status_log.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN payment_status_log.payment_id IS 'Ссылка на платёж';
COMMENT ON COLUMN payment_status_log.status_from IS 'Предыдущий статус';
COMMENT ON COLUMN payment_status_log.status_to IS 'Новый статус';
COMMENT ON COLUMN payment_status_log.source IS 'Источник изменения';
COMMENT ON COLUMN payment_status_log.raw_data IS 'Сырые данные изменения';

CREATE INDEX idx_payment_status_log_payment_id ON payment_status_log(payment_id);
CREATE INDEX idx_payment_status_log_created_at ON payment_status_log(created_at);

-- ----------------------------------------------------------------------------
-- TABLE: payment_polling_attempts
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS payment_polling_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    attempt_number INTEGER NOT NULL,
    result VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_polling_attempts_number CHECK (attempt_number > 0 AND attempt_number <= 10)
);

COMMENT ON TABLE payment_polling_attempts IS 'Попытки опроса статуса платежа у провайдера';
COMMENT ON COLUMN payment_polling_attempts.id IS 'Уникальный идентификатор попытки';
COMMENT ON COLUMN payment_polling_attempts.payment_id IS 'Ссылка на платёж';
COMMENT ON COLUMN payment_polling_attempts.attempt_number IS 'Номер попытки (1-10)';
COMMENT ON COLUMN payment_polling_attempts.result IS 'Результат опроса';

CREATE INDEX idx_payment_polling_attempts_payment_id ON payment_polling_attempts(payment_id);
CREATE INDEX idx_payment_polling_attempts_created_at ON payment_polling_attempts(created_at);

-- ----------------------------------------------------------------------------
-- TABLE: refunds
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS refunds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    reason TEXT NOT NULL,
    status refund_status NOT NULL DEFAULT 'pending',
    initiated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    provider_refund_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_refunds_amount CHECK (amount > 0)
);

COMMENT ON TABLE refunds IS 'Возвраты платежей';
COMMENT ON COLUMN refunds.id IS 'Уникальный идентификатор возврата';
COMMENT ON COLUMN refunds.tenant_id IS 'Тенант';
COMMENT ON COLUMN refunds.payment_id IS 'Ссылка на исходный платёж';
COMMENT ON COLUMN refunds.order_id IS 'Ссылка на заказ';
COMMENT ON COLUMN refunds.amount IS 'Сумма возврата';
COMMENT ON COLUMN refunds.reason IS 'Причина возврата (обязательно)';
COMMENT ON COLUMN refunds.status IS 'Статус возврата';
COMMENT ON COLUMN refunds.initiated_by IS 'Пользователь инициировавший возврат';
COMMENT ON COLUMN refunds.provider_refund_id IS 'ID возврата у провайдера';

CREATE INDEX idx_refunds_tenant_id ON refunds(tenant_id);
CREATE INDEX idx_refunds_payment_id ON refunds(payment_id);
CREATE INDEX idx_refunds_order_id ON refunds(order_id);
CREATE INDEX idx_refunds_status ON refunds(status);
CREATE INDEX idx_refunds_created_at ON refunds(created_at);

-- ----------------------------------------------------------------------------
-- TABLE: fiscal_receipts
-- refund_id для чеков возврата
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS fiscal_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    refund_id UUID REFERENCES refunds(id) ON DELETE SET NULL,
    type receipt_type NOT NULL,
    status receipt_status NOT NULL DEFAULT 'pending',
    ofd_provider VARCHAR(50) NOT NULL,
    fiscal_number VARCHAR(50),
    fiscal_sign VARCHAR(50),
    receipt_data JSONB NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE,
    confirmed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_fiscal_receipts_refund CHECK (
        (type = 'payment' AND refund_id IS NULL) OR
        (type = 'refund' AND refund_id IS NOT NULL)
    )
);

COMMENT ON TABLE fiscal_receipts IS 'Фискальные чеки';
COMMENT ON COLUMN fiscal_receipts.id IS 'Уникальный идентификатор чека';
COMMENT ON COLUMN fiscal_receipts.tenant_id IS 'Тенант';
COMMENT ON COLUMN fiscal_receipts.order_id IS 'Ссылка на заказ';
COMMENT ON COLUMN fiscal_receipts.payment_id IS 'Ссылка на платёж (обязательно)';
COMMENT ON COLUMN fiscal_receipts.refund_id IS 'Ссылка на возврат (для чеков типа refund)';
COMMENT ON COLUMN fiscal_receipts.type IS 'Тип: оплата или возврат';
COMMENT ON COLUMN fiscal_receipts.status IS 'Статус чека';
COMMENT ON COLUMN fiscal_receipts.ofd_provider IS 'ОФД провайдер (platform_ofd, first_ofd, ...)';
COMMENT ON COLUMN fiscal_receipts.fiscal_number IS 'Фискальный номер чека';
COMMENT ON COLUMN fiscal_receipts.fiscal_sign IS 'Фискальный признак';
COMMENT ON COLUMN fiscal_receipts.receipt_data IS 'Полное содержимое чека';
COMMENT ON COLUMN fiscal_receipts.sent_at IS 'Время отправки в ОФД';
COMMENT ON COLUMN fiscal_receipts.confirmed_at IS 'Время подтверждения от ОФД';

CREATE INDEX idx_fiscal_receipts_tenant_id ON fiscal_receipts(tenant_id);
CREATE INDEX idx_fiscal_receipts_order_id ON fiscal_receipts(order_id);
CREATE INDEX idx_fiscal_receipts_payment_id ON fiscal_receipts(payment_id);
CREATE INDEX idx_fiscal_receipts_refund_id ON fiscal_receipts(refund_id);
CREATE INDEX idx_fiscal_receipts_status ON fiscal_receipts(status);
CREATE INDEX idx_fiscal_receipts_type ON fiscal_receipts(type);
CREATE INDEX idx_fiscal_receipts_created_at ON fiscal_receipts(created_at);

-- ----------------------------------------------------------------------------
-- TABLE: cash_shifts
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS cash_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    opened_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    closed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    opened_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    closed_at TIMESTAMP WITH TIME ZONE,
    opening_cash DECIMAL(10,2) NOT NULL DEFAULT 0,
    closing_cash DECIMAL(10,2),
    status cash_shift_status NOT NULL DEFAULT 'open',
    CONSTRAINT chk_cash_shifts_opening CHECK (opening_cash >= 0),
    CONSTRAINT chk_cash_shifts_closing CHECK (closing_cash IS NULL OR closing_cash >= 0)
);

COMMENT ON TABLE cash_shifts IS 'Кассовые смены';
COMMENT ON COLUMN cash_shifts.id IS 'Уникальный идентификатор смены';
COMMENT ON COLUMN cash_shifts.tenant_id IS 'Тенант';
COMMENT ON COLUMN cash_shifts.opened_by IS 'Пользователь открывший смену';
COMMENT ON COLUMN cash_shifts.closed_by IS 'Пользователь закрывший смену';
COMMENT ON COLUMN cash_shifts.opened_at IS 'Время открытия';
COMMENT ON COLUMN cash_shifts.closed_at IS 'Время закрытия';
COMMENT ON COLUMN cash_shifts.opening_cash IS 'Наличные на открытии';
COMMENT ON COLUMN cash_shifts.closing_cash IS 'Наличные на закрытии';
COMMENT ON COLUMN cash_shifts.status IS 'Статус смены';

CREATE INDEX idx_cash_shifts_tenant_id ON cash_shifts(tenant_id);
CREATE INDEX idx_cash_shifts_status ON cash_shifts(status);
CREATE INDEX idx_cash_shifts_opened_at ON cash_shifts(opened_at);
CREATE INDEX idx_cash_shifts_tenant_status ON cash_shifts(tenant_id, status) WHERE status = 'open';

-- Только одна открытая смена на точку
CREATE UNIQUE INDEX idx_one_open_shift_per_tenant 
    ON cash_shifts(tenant_id) 
    WHERE status = 'open';

-- ============================================================================
-- TRIGGER: Автоматическое обновление updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenants_updated_at
    BEFORE UPDATE ON tenants
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_refunds_updated_at
    BEFORE UPDATE ON refunds
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER: Автоматическая генерация order_number при INSERT
-- ============================================================================

CREATE OR REPLACE FUNCTION trg_set_order_number()
RETURNS TRIGGER AS $$
BEGIN
    -- Формат: #YYYYMM-#### (сброс нумерации каждый месяц)
    -- Для сквозной нумерации убрать TO_CHAR(NOW(), 'YYYYMM') и использовать только sequence
    NEW.order_number := '#' || TO_CHAR(NOW(), 'YYYYMM') || '-' || LPAD(NEW.order_sequence::TEXT, 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orders_set_number
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION trg_set_order_number();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- Включён только на таблицах с готовыми политиками
-- ============================================================================

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_orders ON orders
    FOR ALL
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager', 'ук_billing_admin', 'franchise_manager')
        )
    );

-- ИСПРАВЛЕНИЕ: Добавлен franchise_manager для доступа к платежам (отчёты по выручке)
CREATE POLICY rls_tenant_isolation_payments ON payments
    FOR ALL
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager', 'ук_billing_admin', 'franchise_manager')
        )
    );

-- ============================================================================
-- SEED DATA: Первичное заполнение
-- ИСПРАВЛЕНИЕ: Обёрнуто в транзакцию для работы SET LOCAL
-- ============================================================================

BEGIN;

-- Временно отключаем RLS для выполнения seed (требуется суперюзер или BYPASSRLS)
SET LOCAL row_security = off;

-- 1. Создаём тестовый тенант (точка продаж)
INSERT INTO tenants (id, name, type, status, country, currency, timezone)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Coffee Point #1',
    'sales_point',
    'active',
    'RU',
    'RUB',
    'Europe/Moscow'
)
ON CONFLICT (id) DO NOTHING;

-- 2. Создаём пользователя office_manager
-- ВНИМАНИЕ: password_hash должен быть установлен отдельным скриптом!
-- См. файл seed_passwords.sql или npm run seed
INSERT INTO users (id, tenant_id, email, phone, name, password_hash, status)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'office.manager@coffee.local',
    '+79990000001',
    'Иванов Иван Иванович',
    'REPLACE_WITH_BCRYPT_HASH_SEE_SEED_SCRIPT',
    'active'
)
ON CONFLICT (id) DO NOTHING;

-- 3. Назначаем роль office_manager пользователю
-- Используем EXISTS вместо ON CONFLICT для user_roles
INSERT INTO user_roles (user_id, role_id, tenant_id)
SELECT 
    '00000000-0000-0000-0000-000000000001',
    r.id,
    '00000000-0000-0000-0000-000000000001'
FROM roles r
WHERE r.code = 'office_manager'
  AND NOT EXISTS (
    SELECT 1 FROM user_roles ur
    WHERE ur.user_id = '00000000-0000-0000-0000-000000000001'
      AND ur.role_id = r.id
      AND ur.tenant_id = '00000000-0000-0000-0000-000000000001'
  );

-- 4. Создаём базовые feature flags (все выключены)
INSERT INTO feature_flags (tenant_id, module, enabled)
SELECT 
    '00000000-0000-0000-0000-000000000001',
    m.module,
    FALSE
FROM (
    VALUES 
        ('app'),
        ('kiosk'),
        ('smart_locker'),
        ('prep_kitchen'),
        ('push'),
        ('qr_status')
) AS m(module)
ON CONFLICT (tenant_id, module) DO NOTHING;

-- 5. Базовые ингредиенты для примера
INSERT INTO ingredients (id, name, unit, type, is_active)
VALUES 
    ('10000000-0000-0000-0000-000000000001', 'Кофе в зёрнах', 'g', 'raw_material', TRUE),
    ('10000000-0000-0000-0000-000000000002', 'Молоко', 'ml', 'raw_material', TRUE),
    ('10000000-0000-0000-0000-000000000003', 'Сахар', 'g', 'raw_material', TRUE),
    ('10000000-0000-0000-0000-000000000004', 'Стакан 200мл', 'pcs', 'packaging', TRUE),
    ('10000000-0000-0000-0000-000000000005', 'Крышка', 'pcs', 'packaging', TRUE),
    ('10000000-0000-0000-0000-000000000006', 'Эспрессо заготовка', 'ml', 'semi_finished', TRUE),
    ('10000000-0000-0000-0000-000000000007', 'Взбитое молоко', 'ml', 'semi_finished', TRUE)
ON CONFLICT (id) DO NOTHING;

COMMIT;

-- ============================================================================
-- ВЬЮ
-- ============================================================================

CREATE OR REPLACE VIEW v_active_sessions AS
SELECT 
    s.id,
    s.user_id,
    u.email,
    u.phone,
    u.name,
    s.tenant_id,
    t.name AS tenant_name,
    s.role_code,
    s.expires_at,
    s.created_at
FROM sessions s
JOIN users u ON s.user_id = u.id
LEFT JOIN tenants t ON s.tenant_id = t.id
WHERE s.revoked_at IS NULL 
  AND s.expires_at > NOW();

CREATE OR REPLACE VIEW v_orders_with_latest_status AS
SELECT 
    o.*,
    osl.status_to AS current_status,
    osl.created_at AS status_changed_at,
    osl.source AS status_source
FROM orders o
LEFT JOIN LATERAL (
    SELECT status_to, created_at, source
    FROM order_status_log
    WHERE order_id = o.id
    ORDER BY created_at DESC
    LIMIT 1
) osl ON TRUE;

CREATE OR REPLACE VIEW v_open_cash_shifts AS
SELECT 
    cs.*,
    t.name AS tenant_name,
    u_open.name AS opened_by_name,
    u_close.name AS closed_by_name
FROM cash_shifts cs
JOIN tenants t ON cs.tenant_id = t.id
JOIN users u_open ON cs.opened_by = u_open.id
LEFT JOIN users u_close ON cs.closed_by = u_close.id
WHERE cs.status = 'open';

-- ============================================================================
-- КОНЕЦ МИГРАЦИЙ
-- ============================================================================

/*
================================================================================
ИНСТРУКЦИЯ ПО РАЗВЁРТЫВАНИЮ
================================================================================

1. ЗАПУСК МИГРАЦИЙ
   ```bash
   psql -U postgres -d coffee_db -f migrations/001_initial_schema.sql
   ```
   
   Требуется суперюзер или пользователь с BYPASSRLS для выполнения seed.

2. УСТАНОВКА ПАРОЛЯ ПОЛЬЗОВАТЕЛЯ
   После миграций выполните отдельный скрипт для установки bcrypt хеша:
   
   Node.js (seed_passwords.js):
   ```javascript
   const bcrypt = require('bcrypt');
   const { Pool } = require('pg');
   
   const pool = new Pool({ connectionString: process.env.DATABASE_URL });
   
   async function seed() {
     const hash = await bcrypt.hash('admin123', 12);
     await pool.query(
       `UPDATE users SET password_hash = $1 WHERE email = $2`,
       [hash, 'office.manager@coffee.local']
     );
     await pool.end();
   }
   
   seed();
   ```

3. ФОРМАТ НОМЕРА ЗАКАЗА
   Текущий формат: #YYYYMM-#### (например, #202501-0001)
   - Нумерация сбрасывается каждый месяц
   - В феврале будет #202502-0001, в марте #202503-0001
   
   Для сквозной нумерации без сброса изменить триггер:
   ```sql
   CREATE OR REPLACE FUNCTION trg_set_order_number()
   RETURNS TRIGGER AS $$
   BEGIN
       NEW.order_number := '#ORD-' || LPAD(NEW.order_sequence::TEXT, 8, '0');
       RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;
   ```

4. ROW LEVEL SECURITY
   RLS включён на: orders, payments
   
   Перед запросами в приложении устанавливать:
   ```sql
   SET app.current_user_id = 'user-uuid-here';
   SET app.current_tenant_id = 'tenant-uuid-here';
   ```
   
   Для INSERT в orders НЕ нужно указывать order_number и order_sequence:
   ```sql
   INSERT INTO orders (tenant_id, source, total_amount, final_amount, ...)
   VALUES ('tenant-uuid', 'kiosk', 100.00, 100.00, ...);
   -- order_sequence и order_number заполнятся автоматически
   ```

5. РОЛИ И ДОСТУПЫ
   | Роль                  | Заказы | Платежи | Примечание                    |
   |-----------------------|--------|---------|-------------------------------|
   | barista               | ✅     | ❌      | Только табло своей точки      |
   | shift_manager         | ✅     | ✅      | Управление сменой             |
   | office_manager        | ✅     | ✅      | Полный доступ точки           |
   | franchise_manager     | ✅     | ✅      | Все свои точки, отчёты        |
   | ук_global_admin       | ✅     | ✅      | Вся система                   |
   | ук_country_manager    | ✅     | ✅      | По странам                    |
   | ук_billing_admin      | ✅     | ✅      | Финансы и биллинг             |

6. МАСШТАБИРОВАНИЕ НА ФРАНШИЗУ
   При добавлении второй точки:
   - Добавить RLS политики на остальные таблицы
   - Рассмотреть вынос roles и ingredients в shared database
   - Настроить партиционирование orders и payments по tenant_id + created_at

================================================================================
*/
```
apps-fileview.texmex_20260501.02_p0
ядро-платформа 0-2 этап.txt
ядро-платформа 0-2 этап.txt. На экране.