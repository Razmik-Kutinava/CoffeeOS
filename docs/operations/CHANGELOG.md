# CHANGELOG

## v1.20 — 2026-05-14

### Изменено

- Удалён `.cursor/rules/prd-factory-agent.mdc`; операционный процесс перенесён в **`.cursorrules`** и **`docs/agents/AGENTS.md`**: обязательные `ISSUES` при багах, батчевый `SESSION_STATE` (2–3+ шага / смена задачи / ~3–4 коммита), акцент на **коммитах** для истории, продуктовый вход — `docs/product/01_Vision.md`, `02_functional.md`, `03_Business_Logic.md`; `ARCHITECTURE.md` — по явной готовности канона.
- `docs/operations/ISSUES.md`: шапка без PRD Factory, ссылка на `.cursorrules`.

---

## v1.19 — 2026-05-11

### Добавлено

- Миграция `db/migrate/20260511190000_create_production_kitchen_and_supply.rb`:
  - `production_recipes`, `production_batches`, `supply_orders`, `supply_order_items` (FK, CHECK, индексы по core);
  - расширение `ingredients`: поля production/хранения + constraint `chk_ingredient_storage_temp` + частичный индекс по полуфабрикатам (без уникального индекса на `name`).
- Миграция `db/migrate/20260511190500_remove_duplicate_production_batches_semifinished_index.rb`: убран дублирующий индекс по `semifinished_id` у `production_batches`; в `20260511190000` для `references :semifinished` задано `index: false` (чистые новые прогоны без дубля).

### Проверка

- Миграции применены в `development` и `test`.
- Полный тестовый прогон после B5:
  - `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.

### Изменено

- `docs/operations/GAP_LIST_CORE_SCHEMA.md`: прогресс B5, покрытие `62/62`, помечены закрытые пункты `production_*`, `supply_*`.
- `docs/operations/HANDOFF.md`, `docs/operations/SESSION_STATE.md`: батч B5 завершён.

### Причина

Закрыть последний миграционный батч production/supply по core и зафиксировать полное табличное покрытие gap-листа.

---

## v1.18 — 2026-05-11

### Добавлено

- Миграция `db/migrate/20260511184500_create_pickup_tables_and_orders_fields.rb`:
  - `pickup_display_settings`;
  - `pickup_calls`;
  - `pickup_events`;
  - расширение `orders`: `ready_at`, `issued_at`, `pickup_method` + constraint/indexes.

### Проверка

- Миграции применены в `development` и `test`.
- Полный тестовый прогон после B4:
  - `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.

### Изменено

- `docs/operations/GAP_LIST_CORE_SCHEMA.md` обновлён прогрессом B4 и покрытием (`58/62`, `93.5%` с mapping).
- `docs/operations/HANDOFF.md` и `docs/operations/SESSION_STATE.md` переведены на следующий батч B5.

### Причина

Закрыть контур smart pickup (этап 10 core) и подготовить основу для финального production/supply батча.

---

## v1.17 — 2026-05-11

### Добавлено

- Миграция `db/migrate/20260511183000_create_mobile_carts_and_payment_methods.rb`:
  - `mobile_carts`;
  - `mobile_payment_methods`.

### Проверка

- Миграции применены в `development` и `test`.
- Полный тестовый прогон после B3.5:
  - `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.

### Изменено

- `docs/operations/GAP_LIST_CORE_SCHEMA.md` обновлён прогрессом B3.5 и покрытием (`55/62`, `88.7%` с mapping).
- `docs/operations/HANDOFF.md` и `docs/operations/SESSION_STATE.md` переведены на следующий батч B4.

### Причина

Закрыть мобильный слой ядра перед переходом к модулю умной выдачи (pickup), сохраняя стабильность через полный тестовый контур.

---

## v1.16 — 2026-05-11

### Добавлено

- Миграция `db/migrate/20260511181500_create_loyalty_promo_push_feedback.rb`:
  - `loyalty_accounts`;
  - `loyalty_transactions`;
  - `promo_code_usages`;
  - `push_notifications`;
  - `order_feedback`.

### Проверка

- Миграции применены в `development` и `test`.
- Полный тестовый прогон после B3:
  - `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.

### Изменено

- `docs/operations/GAP_LIST_CORE_SCHEMA.md` обновлён прогрессом B3 и покрытием (`53/62`, `85.5%` с mapping).
- `docs/operations/HANDOFF.md` и `docs/operations/SESSION_STATE.md` переведены на следующий батч (B3.5/B4).

### Причина

Закрыть крупный слой мобильной лояльности и коммуникаций до перехода к выдаче (pickup) и production/supply модулям.

---

## v1.15 — 2026-05-11

### Добавлено

- Миграция `db/migrate/20260511180000_create_billing_and_tenant_invitations.rb`:
  - `billing_plans`;
  - `billing_subscriptions`;
  - `tenant_invitations`;
  - `tenants.plan_id` + FK на `billing_plans`.

### Проверка

- Миграции применены в `development` и `test`.
- Полный тестовый прогон после B2:
  - `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.

### Изменено

- `docs/operations/GAP_LIST_CORE_SCHEMA.md` обновлён прогрессом B2 и покрытием (`48/62`, `77.4%` с mapping).
- `docs/operations/HANDOFF.md` и `docs/operations/SESSION_STATE.md` переведены на следующий батч B3.

### Причина

Продолжить синхронизацию ядра безопасными батчами, закрывая приоритетный billing/admin контур до перехода к loyalty/pickup/production.

---

## v1.14 — 2026-05-11

### Добавлено

- Миграция `db/migrate/20260511174500_create_admin_audit_and_feature_flags_logs.rb`:
  - `admin_audit_logs` (tenant/actor/entity/action/details/request_id + индексы);
  - `feature_flags_logs` (tenant/changed_by/module/action/enabled/changed_at/meta + индексы).

### Проверка

- Миграции применены в `development` и `test`.
- Полный тестовый прогон после B1:
  - `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.

### Изменено

- `docs/operations/GAP_LIST_CORE_SCHEMA.md` обновлён прогрессом B1 (добавлены `done-in-b1` отметки и новый coverage с mapping).
- `docs/operations/HANDOFF.md` и `docs/operations/SESSION_STATE.md` переведены на следующий батч B2.

### Причина

Запуск практической синхронизации core->schema с минимальным риском: сначала закрываем audit/log базу и подтверждаем стабильность тестами.

---

## v1.13 — 2026-05-11

### Изменено

- `docs/operations/GAP_LIST_CORE_SCHEMA.md` переведён из чернового списка в рабочий артефакт Шага 2:
  - выполнена классификация всех 25 гэпов (`rename-only` / `missing-table`);
  - назначены батчи исполнения B0..B5;
  - добавлен чек-лист анти-ошибок до/после каждого батча.
- `docs/operations/HANDOFF.md` обновлён на текущий рабочий маршрут: B0 -> B1.
- `docs/operations/SESSION_STATE.md` обновлён: Шаг 1 завершён, классификация зафиксирована, следующий шаг — исполнение батчей.

### Причина

После пользовательского апрува нужен был не только список расхождений, но и управляемый план выполнения с контролем риска, чтобы доводить систему до синхронности без регрессий.

---

## v1.12 — 2026-05-11

### Изменено

- Документация переведена в новый базовый контур: в `docs/product` оставлены только `01_Vision.md`, `02_functional.md`, `03_Business_Logic.md`; остальные материалы перенесены в `docs/archive/2026-05-11-reset`.
- Создан контур ядра в `docs/product/core`: загружены 11 SQL-доков, выровнены имена файлов по смыслу с сохранением нумерации `01..11`.
- Добавлен `docs/product/core/README.md` с картой ядра и порядком чтения.
- В `docs/agents/AGENTS.md` удалён блок «Воркфлоу задачи» по запросу пользователя.

### Анализ

- Проведено сравнение `docs/product/core/*.md` с текущим `db/schema.rb`.
- Покрытие core-ядра по таблицам: `37/62` (≈ `59.7%`).
- Выявлены 2 типа расхождений:
  1. Нейминг/множественное число (`*_log` vs `*_logs`, `*_visibility` vs `*_visibilities`).
  2. Реально отсутствующие в схеме модули поздних этапов (в т.ч. billing, loyalty, pickup, production, push).

### Причина

Система развивалась итеративно под рабочие задачи, поэтому часть модулей реализована частично/в упрощённом виде и не полностью синхронизирована с полной 11-этапной core-спецификацией.

### План

- Шаг 1: зафиксировать `gap-list` core→schema (что уже есть, что rename, что отсутствует).
- Шаг 2: закрывать гэпы батчами по модулям через обратимые миграции + тесты.
- Шаг 3: выполнить сквозной smoke/regression на критичных потоках.
- Шаг 4: pre-prod прогон, rollback-план, затем production rollout.

---

## v1.11 — 2026-05-03

### Добавлено

- Онбординг точки в УК: `Platform::TenantOnboarding::Provision`, `CatalogBootstrap` (авто PTS для активных продуктов), транзакционный create/update в `Platform::TenantsController`.
- Резолвинг витрины по поддомену (`tenants.slug` + `SHOP_BASE_DOMAIN`, прод по умолчанию `coffeeos.fly.dev`), `UrlBuilder` для ссылки в flash после создания точки.
- Переменная `SHOP_BASE_DOMAIN` в `.env.example`; тесты сервисов, контроллера УК, интеграция shop API по Host.

### Причина

Свести создание точки к одному сценарию (модули + каталог + канонический URL) и поддержать мультиточечную витрину по поддомену.

---

## v1.10 — 2026-05-02

### Добавлено

- `docs/product/ARCHITECTURE.md` — секция «Архитектура онбординга организации и точки (v1)»: точка входа в УК, состав доменных сущностей, tenant/RLS-изоляция, поддомены и shop↔tenant, аудит, требования идемпотентности и границы v1.

### Причина

Зафиксировать технический контракт перед реализацией фичи автосоздания организации/точки/доступов.

---

## v1.9 — 2026-05-02

### Добавлено

- `docs/product/PRD.md` — секция «Онбординг организации и точки»: УК создаёт организацию/точку/владельца, автомодули и каталог, поддомены, аудит, без киоска в v1; глоссарий (MVP-скоуп потока, идемпотентность).

### Причина

Фиксация ответов заказчика перед проектированием в ARCHITECTURE и реализацией.

---

## v1.8 — 2026-05-02

### Добавлено

- `.cursor/rules/prd-factory-agent.mdc` — анти-игнор: срочность не отменяет гейты; приоритет операционных правил v10 над расхождениями в `AGENTS.md`; обязательный минимум при конце сессии (`HANDOFF` + `SESSION_STATE`); деструктивные git-операции и Merge Conflict Gate; передачи между ролями и протокол mid-sprint.
- `docs/agents/AGENTS.md` — уточняющие пункты (согласование с v10, одна ведущая роль, конец сессии, git/merge), без удаления существующих правил.

### Причина

Снизить «игнор» инструкций: явные стыки цепочки агентов, запрет обхода протоколов под давлением, разрешение противоречия батчей vs «обновляй всё каждый шаг».

---

## v1.7 — 2026-05-02

### Добавлено

- Rake-задача `shop:catalog:load` — заливка каталога витрины из `db/seeds_shop_catalog.rb` без полного `db:seed`. В production только с `ALLOW_SHOP_CATALOG_LOAD=1`.
- `.env.example` — переменная `ALLOW_SHOP_CATALOG_LOAD` с комментарием.

### Причина

Нужен явный, контролируемый способ наполнить витрину (категории, товары, цены по точкам) в dev и при необходимости на production.

---

## v1.6 — 2026-05-02

### Исправлено

- Shop API: 500 на `GET /shop/api/categories` в production (SolidCache / `Rails.cache.write`) — миграция уникального индекса для cache-БД, безопасное чтение/запись кэша в `Shop::Api::CategoriesController`, деплой без кэша сборки Docker.

### Изменено

- `db/cache_migrate/20260502100000_ensure_solid_cache_key_hash_unique_index.rb` — индекс `key_hash` для Solid Cache upsert.
- `app/controllers/shop/api/categories_controller.rb` — `safe_cache_read` / `safe_cache_write`.
- `db/cache_schema.rb` — версия схемы cache.

### Причина

Solid Cache и Rack::Attack используют разные хранилища; падение оставалось на записи каталога в `Rails.cache`.

---

## v1.5 — 2026-05-01

### Изменено

- `.cursor/rules/prd-factory-agent.mdc` — устранен конфликт между "после каждого действия" и батч-режимом записей.
- `.cursor/rules/prd-factory-agent.mdc` — закреплено: `SESSION_STATE` обновляется после каждого действия (кратко, 1-2 строки).
- `.cursor/rules/prd-factory-agent.mdc` — закреплено: `ISSUES` создается сразу при ошибке, статус/решение дополняются в конце логического шага.
- `.cursor/rules/prd-factory-agent.mdc` — закреплено: `CHANGELOG` и `HANDOFF` обновляются батчем в конце логического шага.
- `.cursor/rules/prd-factory-agent.mdc` — добавлено правило сессии: `PRD` и `ARCHITECTURE` читаются полно один раз, дальше опора на `SESSION_STATE/HANDOFF`.

### Причина

Ускорить работу агента без потери контроля: меньше тяжелых записей и повторных перечитываний при сохранении строгого протокола ошибок и трассировки действий.

---

## v1.4 — 2026-05-01

### Изменено

- `.cursor/rules/prd-factory-agent.mdc` — добавлен `Hard Persistence Gate` (fail-closed): без обязательных обновлений `SESSION_STATE/ISSUES/HANDOFF/CHANGELOG` переход к следующему шагу запрещен.
- `.cursor/rules/prd-factory-agent.mdc` — добавлен обязательный стартовый блок новой сессии: `last_done`, `current_state`, `next_step`.
- `.cursor/rules/prd-factory-agent.mdc` — в `Execution Kernel` добавлена обязательная проверка gate перед отчетом шага.

### Причина

Устранить несистемные пропуски операционных записей и гарантировать непрерывность контекста между сессиями без "памяти по умолчанию".

---

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
