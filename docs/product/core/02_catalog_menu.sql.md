
```sql
-- ============================================================================
-- SQL МИГРАЦИИ ДЛЯ СИСТЕМЫ КОФЕЕН (POSTGRESQL)
-- ЭТАП 3: КАТАЛОГ И МЕНЮ
-- Версия 3.2 - Исправлена инструкция по ручному стопу
-- ============================================================================

-- ============================================================================
-- TABLE: categories (глобальная таблица, создаёт УК)
-- ============================================================================

CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE categories IS 'Категории продуктов (глобальная таблица, создаёт УК)';
COMMENT ON COLUMN categories.id IS 'Уникальный идентификатор категории';
COMMENT ON COLUMN categories.name IS 'Название категории';
COMMENT ON COLUMN categories.slug IS 'URL-слаг для ссылок /menu/{slug}';
COMMENT ON COLUMN categories.sort_order IS 'Порядок сортировки в меню';
COMMENT ON COLUMN categories.is_active IS 'Статус активности категории';
COMMENT ON COLUMN categories.created_by IS 'Пользователь УК создавший категорию';

CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_categories_active ON categories(is_active);
CREATE INDEX idx_categories_sort ON categories(sort_order);

-- ============================================================================
-- TABLE: products (глобальная таблица, создаёт только УК)
-- ============================================================================

CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    is_large_card BOOLEAN NOT NULL DEFAULT FALSE,
    image_url VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    copied_from_id UUID REFERENCES products(id) ON DELETE SET NULL,
    available_countries VARCHAR(10)[],
    available_tenant_ids UUID[],
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE products IS 'Продукты меню (глобальная таблица, создаёт только УК)';
COMMENT ON COLUMN products.id IS 'Уникальный идентификатор продукта';
COMMENT ON COLUMN products.category_id IS 'Категория продукта';
COMMENT ON COLUMN products.name IS 'Название продукта';
COMMENT ON COLUMN products.slug IS 'URL-слаг для маркетинговых ссылок /menu/{slug}';
COMMENT ON COLUMN products.description IS 'Описание продукта';
COMMENT ON COLUMN products.is_large_card IS 'Формат карточки в меню (большая/маленькая)';
COMMENT ON COLUMN products.image_url IS 'URL загруженного фото продукта';
COMMENT ON COLUMN products.is_active IS 'Глобальный статус активности от УК';
COMMENT ON COLUMN products.sort_order IS 'Порядок сортировки внутри категории';
COMMENT ON COLUMN products.copied_from_id IS 'Ссылка на оригинал если это копия';
COMMENT ON COLUMN products.available_countries IS 'Доступные страны (NULL=везде, {RU,KZ}=только эти)';
COMMENT ON COLUMN products.available_tenant_ids IS 'Доступные тенанты (NULL=всем, конкретные UUID=только им)';
COMMENT ON COLUMN products.created_by IS 'Пользователь УК создавший продукт';

CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_slug ON products(slug);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_sort ON products(category_id, sort_order);
CREATE INDEX idx_products_copied_from ON products(copied_from_id);
CREATE INDEX idx_products_countries ON products USING GIN(available_countries);
CREATE INDEX idx_products_tenants ON products USING GIN(available_tenant_ids);

-- ============================================================================
-- TABLE: product_modifier_groups (разделы модификаторов, создаёт УК)
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_modifier_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    is_required BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE product_modifier_groups IS 'Группы модификаторов продуктов (создаёт УК)';
COMMENT ON COLUMN product_modifier_groups.id IS 'Уникальный идентификатор группы';
COMMENT ON COLUMN product_modifier_groups.product_id IS 'Продукт к которому относится группа';
COMMENT ON COLUMN product_modifier_groups.name IS 'Название группы ("Тип молока", "Размер", "Сироп")';
COMMENT ON COLUMN product_modifier_groups.is_required IS 'Обязателен ли выбор из группы';
COMMENT ON COLUMN product_modifier_groups.sort_order IS 'Порядок отображения групп';

CREATE INDEX idx_modifier_groups_product_id ON product_modifier_groups(product_id);
CREATE INDEX idx_modifier_groups_sort ON product_modifier_groups(product_id, sort_order);

-- ============================================================================
-- TABLE: product_modifier_options (опции модификаторов, создаёт УК)
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_modifier_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES product_modifier_groups(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    price_delta DECIMAL(10,2) NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_modifier_price_delta CHECK (price_delta >= 0)
);

COMMENT ON TABLE product_modifier_options IS 'Опции модификаторов (создаёт УК с рекомендованной наценкой)';
COMMENT ON COLUMN product_modifier_options.id IS 'Уникальный идентификатор опции';
COMMENT ON COLUMN product_modifier_options.group_id IS 'Группа модификаторов';
COMMENT ON COLUMN product_modifier_options.name IS 'Название опции ("Овсяное молоко", "Кокосовое молоко")';
COMMENT ON COLUMN product_modifier_options.price_delta IS 'Рекомендованная наценка УК';
COMMENT ON COLUMN product_modifier_options.is_active IS 'Статус активности опции';
COMMENT ON COLUMN product_modifier_options.sort_order IS 'Порядок отображения опций';

CREATE INDEX idx_modifier_options_group_id ON product_modifier_options(group_id);
CREATE INDEX idx_modifier_options_active ON product_modifier_options(is_active);
CREATE INDEX idx_modifier_options_sort ON product_modifier_options(group_id, sort_order);

-- ============================================================================
-- TABLE: modifier_option_tenant_settings (локальная наценка партнёра)
-- ============================================================================

CREATE TABLE IF NOT EXISTS modifier_option_tenant_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES product_modifier_options(id) ON DELETE CASCADE,
    price_delta_override DECIMAL(10,2) NOT NULL,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, option_id),
    CONSTRAINT chk_tenant_modifier_price CHECK (price_delta_override >= 0)
);

COMMENT ON TABLE modifier_option_tenant_settings IS 'Локальная наценка партнёра на опции модификаторов';
COMMENT ON COLUMN modifier_option_tenant_settings.id IS 'Уникальный идентификатор настройки';
COMMENT ON COLUMN modifier_option_tenant_settings.tenant_id IS 'Тенант (точка продаж)';
COMMENT ON COLUMN modifier_option_tenant_settings.option_id IS 'Опция модификатора';
COMMENT ON COLUMN modifier_option_tenant_settings.price_delta_override IS 'Локальная наценка партнёра';
COMMENT ON COLUMN modifier_option_tenant_settings.updated_by IS 'Пользователь изменивший наценку';

CREATE INDEX idx_tenant_modifier_settings_tenant ON modifier_option_tenant_settings(tenant_id);
CREATE INDEX idx_tenant_modifier_settings_option ON modifier_option_tenant_settings(option_id);

-- ============================================================================
-- TABLE: menu_types (справочник типов меню)
-- ============================================================================

CREATE TABLE IF NOT EXISTS menu_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL
);

COMMENT ON TABLE menu_types IS 'Справочник типов меню (kiosk, app, staff)';
COMMENT ON COLUMN menu_types.id IS 'Уникальный идентификатор типа меню';
COMMENT ON COLUMN menu_types.code IS 'Код типа меню';
COMMENT ON COLUMN menu_types.name IS 'Название типа меню';

INSERT INTO menu_types (code, name) VALUES
('kiosk', 'Киоск самообслуживания'),
('app', 'Мобильное приложение'),
('staff', 'Персонал')
ON CONFLICT (code) DO NOTHING;

CREATE INDEX idx_menu_types_code ON menu_types(code);

-- ============================================================================
-- TABLE: product_menu_visibility (видимость продукта в меню — УК)
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_menu_visibility (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    menu_type_id UUID NOT NULL REFERENCES menu_types(id) ON DELETE CASCADE,
    is_visible BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE(product_id, menu_type_id)
);

COMMENT ON TABLE product_menu_visibility IS 'Видимость продукта в типах меню (настраивает УК)';
COMMENT ON COLUMN product_menu_visibility.id IS 'Уникальный идентификатор настройки';
COMMENT ON COLUMN product_menu_visibility.product_id IS 'Продукт';
COMMENT ON COLUMN product_menu_visibility.menu_type_id IS 'Тип меню';
COMMENT ON COLUMN product_menu_visibility.is_visible IS 'Видимость в данном типе меню';

CREATE INDEX idx_menu_visibility_product ON product_menu_visibility(product_id);
CREATE INDEX idx_menu_visibility_menu_type ON product_menu_visibility(menu_type_id);

-- ============================================================================
-- TABLE: product_tenant_settings (настройки продукта на точке — партнёр)
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_tenant_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    price DECIMAL(10,2),
    is_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    is_sold_out BOOLEAN NOT NULL DEFAULT FALSE,
    sold_out_reason VARCHAR(50),
    stock_qty INTEGER,
    price_updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    price_updated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, product_id),
    CONSTRAINT chk_price_positive CHECK (price IS NULL OR price > 0),
    CONSTRAINT chk_stock_qty CHECK (stock_qty IS NULL OR stock_qty >= 0),
    CONSTRAINT chk_enabled_requires_price CHECK (is_enabled = FALSE OR price IS NOT NULL),
    CONSTRAINT chk_sold_out_reason CHECK (sold_out_reason IS NULL OR sold_out_reason IN ('manual', 'stock_empty'))
);

COMMENT ON TABLE product_tenant_settings IS 'Настройки продукта на точке (партнёр устанавливает цену и статус)';
COMMENT ON COLUMN product_tenant_settings.id IS 'Уникальный идентификатор настройки';
COMMENT ON COLUMN product_tenant_settings.tenant_id IS 'Тенант (точка продаж)';
COMMENT ON COLUMN product_tenant_settings.product_id IS 'Продукт';
COMMENT ON COLUMN product_tenant_settings.price IS 'Цена на точке (NULL = цена не задана, нельзя включить)';
COMMENT ON COLUMN product_tenant_settings.is_enabled IS 'Партнёр включил позицию в меню';
COMMENT ON COLUMN product_tenant_settings.is_sold_out IS 'Раскупили: ручное или автоматическое';
COMMENT ON COLUMN product_tenant_settings.sold_out_reason IS 'Причина стопа: manual | stock_empty';
COMMENT ON COLUMN product_tenant_settings.stock_qty IS 'Остаток (NULL = не отслеживается, 0 = триггер ставит стоп)';
COMMENT ON COLUMN product_tenant_settings.price_updated_by IS 'Пользователь изменивший цену';
COMMENT ON COLUMN product_tenant_settings.price_updated_at IS 'Время последнего изменения цены';

CREATE INDEX idx_tenant_settings_tenant ON product_tenant_settings(tenant_id);
CREATE INDEX idx_tenant_settings_product ON product_tenant_settings(product_id);
CREATE INDEX idx_tenant_settings_enabled ON product_tenant_settings(is_enabled);
CREATE INDEX idx_tenant_settings_sold_out ON product_tenant_settings(is_sold_out);
CREATE INDEX idx_tenant_settings_tenant_product ON product_tenant_settings(tenant_id, product_id);
CREATE INDEX idx_tenant_settings_tenant_enabled ON product_tenant_settings(tenant_id, is_enabled) WHERE is_enabled = TRUE;

-- ============================================================================
-- TABLE: product_price_history (лог изменений цены)
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    price_old DECIMAL(10,2),
    price_new DECIMAL(10,2) NOT NULL,
    changed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE product_price_history IS 'История изменений цен на продукты';
COMMENT ON COLUMN product_price_history.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN product_price_history.tenant_id IS 'Тенант';
COMMENT ON COLUMN product_price_history.product_id IS 'Продукт';
COMMENT ON COLUMN product_price_history.price_old IS 'Старая цена (NULL для первой записи)';
COMMENT ON COLUMN product_price_history.price_new IS 'Новая цена';
COMMENT ON COLUMN product_price_history.changed_by IS 'Пользователь изменивший цену';

CREATE INDEX idx_price_history_tenant_product ON product_price_history(tenant_id, product_id);
CREATE INDEX idx_price_history_created_at ON product_price_history(created_at);
CREATE INDEX idx_price_history_tenant ON product_price_history(tenant_id);

-- ============================================================================
-- TRIGGER: Автоматическое обновление updated_at
-- ============================================================================

CREATE TRIGGER trg_categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_tenant_settings_updated_at
    BEFORE UPDATE ON product_tenant_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER: Автоматический стоп-лист при нулевом остатке
-- ============================================================================

CREATE OR REPLACE FUNCTION trg_auto_sold_out_handler()
RETURNS TRIGGER AS $$
BEGIN
    -- Если остаток стал 0 → автоматически ставим стоп
    IF NEW.stock_qty = 0 AND (OLD.stock_qty IS NULL OR OLD.stock_qty > 0) THEN
        NEW.is_sold_out := TRUE;
        NEW.sold_out_reason := 'stock_empty';
    END IF;
    
    -- Если остаток пополнен И причина стопа была автоматической → снимаем стоп
    -- Ручной стоп (sold_out_reason = 'manual') НЕ снимается автоматически
    IF NEW.stock_qty > 0 AND OLD.is_sold_out = TRUE AND OLD.sold_out_reason = 'stock_empty' THEN
        NEW.is_sold_out := FALSE;
        NEW.sold_out_reason := NULL;
    END IF;
    
    -- Если stock_qty сброшен в NULL (перестали отслеживать)
    -- Ручной стоп не трогаем, автостоп снимаем
    IF NEW.stock_qty IS NULL AND OLD.sold_out_reason = 'stock_empty' THEN
        NEW.is_sold_out := FALSE;
        NEW.sold_out_reason := NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_sold_out
    BEFORE UPDATE ON product_tenant_settings
    FOR EACH ROW
    EXECUTE FUNCTION trg_auto_sold_out_handler();

-- ============================================================================
-- TRIGGER: Логирование изменений цены
-- ============================================================================

CREATE OR REPLACE FUNCTION trg_price_history_logger()
RETURNS TRIGGER AS $$
BEGIN
    -- Записываем в историю только если цена изменилась
    IF (OLD.price IS DISTINCT FROM NEW.price) AND NEW.price IS NOT NULL THEN
        INSERT INTO product_price_history (tenant_id, product_id, price_old, price_new, changed_by)
        VALUES (
            NEW.tenant_id, 
            NEW.product_id, 
            OLD.price, 
            NEW.price, 
            COALESCE(NEW.price_updated_by, OLD.price_updated_by)
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_price_history_log
    AFTER UPDATE ON product_tenant_settings
    FOR EACH ROW
    WHEN (OLD.price IS DISTINCT FROM NEW.price)
    EXECUTE FUNCTION trg_price_history_logger();

-- ============================================================================
-- VIEW: v_active_menu — активное меню точки для киоска и app
-- ============================================================================

CREATE OR REPLACE VIEW v_active_menu AS
SELECT 
    p.id AS product_id,
    p.name,
    p.slug,
    p.description,
    p.image_url,
    p.is_large_card,
    p.sort_order,
    c.id AS category_id,
    c.name AS category_name,
    c.sort_order AS category_sort_order,
    pts.tenant_id,
    pts.price,
    pts.is_sold_out,
    pts.stock_qty
FROM products p
JOIN categories c ON p.category_id = c.id
JOIN product_tenant_settings pts ON p.id = pts.product_id
WHERE p.is_active = TRUE
  AND c.is_active = TRUE
  AND pts.is_enabled = TRUE
  AND pts.is_sold_out = FALSE
  AND pts.price IS NOT NULL;

COMMENT ON VIEW v_active_menu IS 'Активное меню точки для киоска и app (только доступные для заказа продукты)';

-- ============================================================================
-- VIEW: v_product_catalog — полный каталог для интерфейса УК
-- ============================================================================

CREATE OR REPLACE VIEW v_product_catalog AS
SELECT 
    p.id AS product_id,
    p.name,
    p.slug,
    p.description,
    p.image_url,
    p.is_large_card,
    p.is_active,
    p.sort_order,
    p.copied_from_id,
    p.available_countries,
    p.available_tenant_ids,
    c.id AS category_id,
    c.name AS category_name,
    c.slug AS category_slug,
    p_orig.name AS copied_from_name,
    p.created_by,
    p.created_at,
    p.updated_at
FROM products p
JOIN categories c ON p.category_id = c.id
LEFT JOIN products p_orig ON p.copied_from_id = p_orig.id;

COMMENT ON VIEW v_product_catalog IS 'Полный каталог продуктов для интерфейса УК (включая неактивные)';

-- ============================================================================
-- VIEW: v_product_full_info — полная информация о продукте с модификаторами
-- ============================================================================

CREATE OR REPLACE VIEW v_product_full_info AS
SELECT 
    p.id AS product_id,
    p.name AS product_name,
    p.slug AS product_slug,
    c.name AS category_name,
    pmg.id AS modifier_group_id,
    pmg.name AS modifier_group_name,
    pmg.is_required,
    pmg.sort_order AS group_sort_order,
    pmo.id AS modifier_option_id,
    pmo.name AS modifier_option_name,
    pmo.price_delta AS recommended_price_delta,
    pmo.is_active AS option_is_active,
    pmo.sort_order AS option_sort_order
FROM products p
JOIN categories c ON p.category_id = c.id
LEFT JOIN product_modifier_groups pmg ON p.id = pmg.product_id
LEFT JOIN product_modifier_options pmo ON pmg.id = pmo.group_id
ORDER BY p.sort_order, pmg.sort_order, pmo.sort_order;

COMMENT ON VIEW v_product_full_info IS 'Полная информация о продукте со всеми модификаторами и опциями';

-- ============================================================================
-- VIEW: v_tenant_menu_with_prices — меню точки с итоговыми ценами на модификаторы
-- ============================================================================

CREATE OR REPLACE VIEW v_tenant_menu_with_prices AS
SELECT 
    pts.tenant_id,
    pts.product_id,
    p.name AS product_name,
    p.slug AS product_slug,
    pts.price AS base_price,
    pmg.id AS modifier_group_id,
    pmg.name AS modifier_group_name,
    pmg.is_required,
    pmo.id AS modifier_option_id,
    pmo.name AS modifier_option_name,
    pmo.price_delta AS recommended_delta,
    COALESCE(mots.price_delta_override, pmo.price_delta) AS final_price_delta
FROM product_tenant_settings pts
JOIN products p ON pts.product_id = p.id
LEFT JOIN product_modifier_groups pmg ON p.id = pmg.product_id
LEFT JOIN product_modifier_options pmo ON pmg.id = pmo.group_id
LEFT JOIN modifier_option_tenant_settings mots 
    ON pts.tenant_id = mots.tenant_id AND pmo.id = mots.option_id
WHERE pts.is_enabled = TRUE
  AND p.is_active = TRUE;

COMMENT ON VIEW v_tenant_menu_with_prices IS 'Меню точки с итоговыми ценами на модификаторы (с учётом локальных наценок)';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE product_tenant_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE modifier_option_tenant_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_price_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_product_settings ON product_tenant_settings
    FOR ALL
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager', 'office_manager', 'franchise_manager')
        )
    );

CREATE POLICY rls_tenant_modifier_settings ON modifier_option_tenant_settings
    FOR ALL
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager', 'office_manager', 'franchise_manager')
        )
    );

CREATE POLICY rls_tenant_price_history ON product_price_history
    FOR ALL
    USING (
        tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'ук_country_manager', 'ук_billing_admin', 'office_manager', 'franchise_manager')
        )
    );

-- ============================================================================
-- SEED DATA: Первичное заполнение
-- ============================================================================

BEGIN;

SET LOCAL row_security = off;

-- 1. Категория "Кофе"
INSERT INTO categories (id, name, slug, sort_order, is_active, created_by)
VALUES (
    '20000000-0000-0000-0000-000000000001',
    'Кофе',
    'coffee',
    1,
    TRUE,
    NULL
)
ON CONFLICT (id) DO NOTHING;

-- 2. Продукт "Капучино M"
INSERT INTO products (id, category_id, name, slug, description, is_large_card, is_active, sort_order, created_by)
VALUES (
    '30000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    'Капучино M',
    'cappuccino-m',
    'Классический капучино сбалансированного вкуса',
    FALSE,
    TRUE,
    1,
    NULL
)
ON CONFLICT (id) DO NOTHING;

-- 3. Группа модификаторов "Тип молока"
INSERT INTO product_modifier_groups (id, product_id, name, is_required, sort_order)
VALUES (
    '40000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    'Тип молока',
    TRUE,
    1
)
ON CONFLICT (id) DO NOTHING;

-- 4. Опции модификаторов
INSERT INTO product_modifier_options (id, group_id, name, price_delta, is_active, sort_order) VALUES
('50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', 'Обычное молоко', 0, TRUE, 1),
('50000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000001', 'Овсяное молоко', 60, TRUE, 2),
('50000000-0000-0000-0000-000000000003', '40000000-0000-0000-0000-000000000001', 'Кокосовое молоко', 80, TRUE, 3)
ON CONFLICT (id) DO NOTHING;

-- 5. Видимость в меню (kiosk и app, не в staff)
INSERT INTO product_menu_visibility (product_id, menu_type_id, is_visible)
SELECT 
    '30000000-0000-0000-0000-000000000001',
    mt.id,
    TRUE
FROM menu_types mt
WHERE mt.code IN ('kiosk', 'app')
ON CONFLICT (product_id, menu_type_id) DO NOTHING;

-- 6. Настройки продукта для тестового тенанта
INSERT INTO product_tenant_settings (tenant_id, product_id, price, is_enabled, is_sold_out, stock_qty, price_updated_by)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    350,
    TRUE,
    FALSE,
    20,
    '00000000-0000-0000-0000-000000000001'
)
ON CONFLICT (tenant_id, product_id) DO NOTHING;

COMMIT;

-- ============================================================================
-- ФУНКЦИИ ПОМОЩНИКИ
-- ============================================================================

CREATE OR REPLACE FUNCTION get_modifier_option_price(
    p_tenant_id UUID,
    p_option_id UUID
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    v_price DECIMAL(10,2);
BEGIN
    SELECT COALESCE(mots.price_delta_override, pmo.price_delta)
    INTO v_price
    FROM product_modifier_options pmo
    LEFT JOIN modifier_option_tenant_settings mots 
        ON pmo.id = mots.option_id AND mots.tenant_id = p_tenant_id
    WHERE pmo.id = p_option_id;
    
    RETURN v_price;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION is_product_available_for_tenant(
    p_product_id UUID,
    p_tenant_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_tenant tenants%ROWTYPE;
    v_product products%ROWTYPE;
BEGIN
    SELECT * INTO v_tenant FROM tenants WHERE id = p_tenant_id;
    SELECT * INTO v_product FROM products WHERE id = p_product_id;
    
    IF v_product.available_countries IS NOT NULL THEN
        IF NOT v_tenant.country = ANY(v_product.available_countries) THEN
            RETURN FALSE;
        END IF;
    END IF;
    
    IF v_product.available_tenant_ids IS NOT NULL THEN
        IF p_tenant_id != ALL(v_product.available_tenant_ids) THEN
            RETURN FALSE;
        END IF;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- ФУНКЦИЯ: Копировать продукт со всеми модификаторами (только для УК)
-- ============================================================================

CREATE OR REPLACE FUNCTION copy_product(
    p_source_product_id UUID,
    p_new_name VARCHAR(255),
    p_new_slug VARCHAR(255),
    p_created_by UUID
)
RETURNS UUID AS $$
DECLARE
    v_new_product_id UUID;
    v_new_group_id UUID;
    v_old_group_id UUID;
BEGIN
    -- Копируем продукт
    INSERT INTO products (
        category_id, name, slug, description, is_large_card,
        image_url, is_active, sort_order, copied_from_id,
        available_countries, available_tenant_ids, created_by
    )
    SELECT 
        category_id, p_new_name, p_new_slug, description, is_large_card,
        image_url, FALSE, sort_order, id,
        available_countries, available_tenant_ids, p_created_by
    FROM products
    WHERE id = p_source_product_id
    RETURNING id INTO v_new_product_id;
    
    -- Копируем группы модификаторов и опции
    FOR v_old_group_id IN 
        SELECT id FROM product_modifier_groups WHERE product_id = p_source_product_id
    LOOP
        INSERT INTO product_modifier_groups (product_id, name, is_required, sort_order)
        SELECT v_new_product_id, name, is_required, sort_order
        FROM product_modifier_groups
        WHERE id = v_old_group_id
        RETURNING id INTO v_new_group_id;
        
        INSERT INTO product_modifier_options (group_id, name, price_delta, is_active, sort_order)
        SELECT v_new_group_id, name, price_delta, is_active, sort_order
        FROM product_modifier_options
        WHERE group_id = v_old_group_id;
    END LOOP;
    
    -- Копируем видимость в меню
    INSERT INTO product_menu_visibility (product_id, menu_type_id, is_visible)
    SELECT v_new_product_id, menu_type_id, is_visible
    FROM product_menu_visibility
    WHERE product_id = p_source_product_id;
    
    RETURN v_new_product_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- КОНЕЦ МИГРАЦИЙ ЭТАПА 3
-- ============================================================================

/*
================================================================================
ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ

1. КАК ДОБАВИТЬ НОВЫЙ ПРОДУКТ ЧЕРЕЗ SQL (только УК-роли)

   INSERT INTO categories (name, slug, sort_order, created_by)
   VALUES ('Чай', 'tea', 2, 'user-uuid-here')
   ON CONFLICT (slug) DO UPDATE SET name = 'Чай';
   
   INSERT INTO products (category_id, name, slug, description, is_active, created_by)
   VALUES (
       (SELECT id FROM categories WHERE slug = 'tea'),
       'Чай Латте M',
       'tea-latte-m',
       'Нежный чай с молоком',
       TRUE,
       'user-uuid-here'
   );

2. КАК ПАРТНЁР УСТАНАВЛИВАЕТ ЦЕНУ

   INSERT INTO product_tenant_settings (tenant_id, product_id, price, is_enabled)
   VALUES ('tenant-uuid', 'product-uuid', 350, TRUE)
   ON CONFLICT (tenant_id, product_id) 
   DO UPDATE SET price = 350, price_updated_at = NOW();

3. КАК РАБОТАЕТ АВТОСТОП

   -- Автоматический стоп при stock_qty = 0
   UPDATE product_tenant_settings SET stock_qty = 0 WHERE ...;
   -- Триггер: is_sold_out=TRUE, sold_out_reason='stock_empty'
   
   -- Пополнение (автостоп снимется)
   UPDATE product_tenant_settings SET stock_qty = 50 WHERE ...;
   -- Триггер: is_sold_out=FALSE, sold_out_reason=NULL
   
   -- Ручной стоп (устанавливать ОБА поля!)
   UPDATE product_tenant_settings 
   SET is_sold_out = TRUE, sold_out_reason = 'manual' 
   WHERE ...;
   
   -- Снять ручной стоп вручную
   UPDATE product_tenant_settings 
   SET is_sold_out = FALSE, sold_out_reason = NULL 
   WHERE ...;
   
   -- Сброс отслеживания (stock_qty = NULL, автостоп снимется)
   UPDATE product_tenant_settings SET stock_qty = NULL WHERE ...;

4. КОПИРОВАНИЕ ПРОДУКТА (только УК)

   SELECT copy_product(
       'original-product-uuid',
       'Капучино M (Копия)',
       'cappuccino-m-copy',
       'uk-admin-user-uuid'
   );
   -- Копируются: продукт, все группы модификаторов, все опции, видимость в меню

================================================================================
ИСПРАВЛЕНИЯ В ЭТОЙ ВЕРСИИ

1. ✅ Триггер автостопа обрабатывает NULL в stock_qty
   - При установке stock_qty = NULL автостоп снимается
   - Ручной стоп ('manual') не затрагивается

2. ✅ Триггер логирования цены использует COALESCE для changed_by
   - Если NEW.price_updated_by NULL, берётся из OLD
   - История не теряет автора изменения

3. ✅ Функция copy_product копирует product_menu_visibility
   - Копия продукта наследует видимость в меню от оригинала

4. ✅ Исправлена инструкция по ручному стопу
   - Теперь указано что нужно устанавливать ОБА поля:
     is_sold_out = TRUE И sold_out_reason = 'manual'

================================================================================
*/
```
apps-fileview.texmex_20260501.02_p0
ядро-платформа 3 этап.txt
ядро-платформа 3 этап.txt. На экране.