# CHANGELOG

## v1.3 — 2026-04-30

### Добавлено

- SESSION_STATE.md — текущее состояние проекта, следующий шаг, блокеры
- HANDOFF.md — текущий спринт, задача, статус
- config/initializers/shop_api_auth.rb — Auth модуль с проверкой API ключа
- config/initializers/shop_api_error_handler.rb — ErrorHandler модуль
- app/policies/* — Pundit политики для всех доменов
- test/integration/shop/* — интеграционные тесты shop API
- test/services/shop/* — сервисные тесты shop

### Изменено

- .cursor/rules/prd-factory-agent.mdc — оптимизирован до v10 (347 строк вместо 1637)
- AGENTS.md — обновлен для v10 (HANDOFF.md в порядке чтения)
- START.md — обновлен для v10 (HANDOFF.md в порядке чтения)
- app/controllers/shop/api/base_controller.rb — CSRF защита изменена на :null_session
- app/controllers/shop/api/cart_controller.rb — валидация параметров
- app/controllers/shop/api/categories_controller.rb — кэширование и пагинация
- app/controllers/shop/api/products_controller.rb — кэширование и пагинация
- app/controllers/shop/api/orders_controller.rb — логирование и пагинация
- app/services/shop/cart_service.rb — лимиты товаров

### Git

- Коммит: f2b157e — fix: исправлены ошибки Shop API и оптимизирована инструкция агента v10
- Пуш: develop обновлен

### Причина

Оптимизация инструкции агента v10. Исправление ошибок Shop API (500 error). Добавлена авторизация, обработка ошибок, валидация, кэширование, пагинация, логирование. Тесты проходят.

---

## v1.2 — 2026-04-30

### Добавлено

- SESSION_STATE.md — текущее состояние проекта, следующий шаг, блокеры
- HANDOFF.md — текущий спринт, задача, статус

### Изменено

- .cursor/rules/prd-factory-agent.mdc — оптимизирован до v10 (347 строк вместо 1637)
- .cursor/rules/prd-factory-agent.mdc — удалена устаревшая версия v6.0
- AGENTS.md — обновлен для v10 (HANDOFF.md в порядке чтения)
- START.md — обновлен для v10 (HANDOFF.md в порядке чтения)

### Причина

Оптимизация инструкции агента для повышения эффективности и снижения контекста. Удалена дублирующаяся устаревшая версия v6.0, оставлена только актуальная v10. Добавлен HANDOFF.md для отслеживания спринтов.

---

## v1.1 — 2026-04-30

### Добавлено

- Правила ведения документов в .cursor/rules/prd-factory-agent.mdc
- Правила чтения SESSION_STATE.md и CHANGELOG.md в AGENTS.md
- Раздел о восстановлении контекста в START.md

### Изменено

- .cursor/rules/prd-factory-agent.mdc — добавлено правило о ведении документов после каждого шага
- AGENTS.md — добавлено правило о чтении SESSION_STATE.md и CHANGELOG.md
- START.md — добавлен раздел "Новый диалог — восстановление контекста"

### Причина

Обеспечить непрерывность контекста между диалогами. Агент теперь автоматически ведёт SESSION_STATE.md, CHANGELOG.md и ISSUES.md после каждого шага.

---

## v1.0 — 2026-04-29

### Добавлено

**Документы PRD Factory:**
- PRD.md — суть продукта, роли, P1/P2/P3, метрики успеха
- ARCHITECTURE.md — структура проекта, схема БД, API-контракты, модули
- AGENTS.md — воркфлоу задачи, правила работы, Definition of Done
- CHANGELOG.md — история изменений
- ISSUES.md — трекер проблем
- START.md — инструкция старта проекта
- SPRINT_1_PROMPT.md — промпт первого спринта
- .env.example — ENV переменные с SHOP_API_KEY

**Код:**
- Shop API авторизация (config/initializers/shop_api_auth.rb)
- Shop API обработка ошибок (config/initializers/shop_api_error_handler.rb)
- Solid Cache конфигурация (config/initializers/solid_cache.rb)
- Модель PromoCode с методом active?
- Промокод coffeefree в seeds (db/seeds_shop_promo_code.rb)

**Миграции:**
- 20260428000001_create_solid_cache_entries.rb
- 20260428000002_fix_rls_product_tenant_settings_franchise_isolation.rb

**Тесты:**
- test/integration/shop/api/categories_controller_test.rb
- test/integration/shop/api/orders_controller_test.rb

**Документация:**
- docs/shop_api_auth.md

### Изменено

**Контроллеры:**
- app/controllers/shop/api/base_controller.rb — CSRF защита
- app/controllers/shop/api/cart_controller.rb — валидация параметров
- app/controllers/shop/api/products_controller.rb — пагинация
- app/controllers/shop/api/categories_controller.rb — пагинация + кэширование
- app/controllers/shop/api/orders_controller.rb — пагинация

**Сервисы:**
- app/services/shop/cart_service.rb — лимиты товаров
- app/services/shop/order_creator.rb — промокоды

**Модели:**
- app/models/refund.rb — исправление lock
- app/models/payment.rb — RLS политика для franchise_manager

**Конфигурация:**
- config/environments/test.rb — memory_store вместо null_store
- config/initializers/rack_attack.rb — логирование с защитой от Hash
- test/support/factories.rb — create_mobile_customer!, login_as! с tenant_id

### Причина

Привести документацию к единому процессу PRD Factory и обеспечить непрерывность контекста между диалогами.
