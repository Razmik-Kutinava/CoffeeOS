# SESSION_STATE

## Текущее состояние

**Дата:** 2026-06-01  
**Веха 1:** официально не закрыта (§ I, H.3 — `[ ]`).  
**Веха 2:** **в работе**; прогон 10 этапы 0–2 **PASS**; **добивка** — блоки 1–14 ([`milestones/veha_2/QA_ACCEPTANCE_RUN.md`](milestones/veha_2/QA_ACCEPTANCE_RUN.md)).  
**§I веха:** **не закрыта** (§E, апрув, «веха закрыта» — после блоков + фидбек).

**Прогона 11 нет.** Scope продолжения: без Flutter / живого демо / живой оплаты; MCP-витрина **5** точек.

| Сейчас | Дальше |
|--------|--------|
| Блок **5** ✅ — gate тестов и sync CR | Блок **3** — CR-05, CR-04 |
| Блок **0–2,4** выполнены | … блоки 6–14 |

**Ops на блок:** `SESSION_STATE` + коммит всегда; `PRACTICES` (CR); `QA_ACCEPTANCE_RUN` + `artifacts/` (QA); `CHANGELOG` если заметно; `CHECKLIST` `[x]` только по факту.

### Сессия 2026-06-02 (прогон 10 — блок 5, gate кода)

- Полный `bin/rails test` в WSL: **559 runs, 2311 assertions, 0 failures**.
- Синхронизированы статусы блока 5 в `QA_ACCEPTANCE_RUN`, `PRACTICES`, `CODE_REVIEW`.
- Код не меняли; только ops-фиксация статуса gate.
- Следующий: блок 3 (CR-05, CR-04).

### Сессия 2026-06-02 (прогон 10 — блок 4, ops)

- **V2-CR-02:** auto-check секретов на Fly не выполнен — в среде нет `flyctl`.
- **Зафиксировано:** manual-check перед deploy обязателен (`CALLBACK_SHARED_SECRET`, `CALLBACK_SHARED_TOKEN` в Fly).
- **SEC-07:** `shop-api-key` в meta оставлен как backlog (демо-стенд).
- **Тесты:** suite **559/0**.
- **Следующий:** блок 3 (CR-05, CR-04).

### Сессия 2026-06-01 (прогон 10 — блок 2, витрина)

- **CSRF:** витрина в браузере — проверяем настоящий токен, не только заголовок.
- **Заказы:** чужой гость не видит заказ по id (только свой в сессии).
- **Тесты:** shop auth/orders 13/0; suite **559/0**.
- **Следующий:** блок 3 (kiosk GUC, CacheCounter).

### Сессия 2026-06-01 (прогон 10 — блок 1, код perf)

- **Код:** `CatalogBootstrap` — один prefetch PTS; `EntryPoints` — один запрос FeatureFlag.
- **Тесты:** onboarding 9/0; полный suite **555/0** (WSL).
- **Ops:** V2-CR-01 done, V2-006 в CODE_REVIEW; блок 1 ✅ в QA таблице.
- **Следующий:** блок 2 (CR-03, SEC-08).

### Сессия 2026-06-01 (прогон 10 — блок 0, план добивки)

- Зафиксированы: нет прогона 11; scope; таблица блоков 0–14; правило ops.
- Доки: `QA_ACCEPTANCE_RUN`, `PRACTICES`, `CODE_REVIEW`, `CHANGELOG` v1.77.
- **Код не трогали.** Следующий шаг: **блок 1** после апрува.

### Сессия 2026-06-01 (прогон 10c — финал QA)

- Shop 9×, stress wave 2, kiosk cash+card 9×, Prog10 barista login, prep, logout.
- Коммит `docs(ops): prog10c close full QA acceptance scope`.

### Сессия 2026-06-01 (прогон 10b)

- 9× cash/card, kiosk, RBAC, checkout MCP.

### Сессия 2026-05-30 (прогон 10 — черновик)

- Промежуточный журнал → дополнен 2026-06-01 (см. выше).

### Сессия 2026-05-30 (V2-T8 — flaky events_controller_test) — **done**

- **Проблема:** тест callback anti-replay — timestamp «299 с назад» на границе 300 с → иногда 401.
- **Fix:** `travel_to` + **200 с** запас; `ActiveSupport::Testing::TimeHelpers` в тест-классе.
- **Прогон:** `events_controller_test.rb` **23/0**; целевой тест **×5 PASS**.
- **Ops:** V2-T8 done — `PRACTICES`, `CHECKLIST` §H, `POSTMORTEM`, `CHANGELOG` v1.69.
- **§I:** не трогали.

### Сессия 2026-05-30 (Kiosk auth API — без закрытия §I)

- **Код:** `POST /kiosk/api/auth` (`c44b1eb`).
- **Docs:** FLUTTER_API, postmortem черновик.
- **§I:** галочки **не** ставить без апрува заказчика.

### Сессия 2026-05-25 (Fly URL: режим B vs поддомены A)

- **Проблема:** `fly certs add "*.coffeeos.fly.dev"` → ACME отказ; поддомены `{slug}.coffeeos.fly.dev` не резолвятся.
- **Решение:** два режима в `docs/operations/SHOP_URL_MODES.md`. Fly demo = `?tenant_id=`; канон прод = `{slug}.{SHOP_BASE_DOMAIN}`. Slug в БД не трогаем.
- **Код:** `UrlBuilder` без дефолта домена; `fly.toml` без `SHOP_BASE_DOMAIN`; `demo:shop_urls`.
- **Следующий шаг владельца:** deploy develop → `fly ssh … demo:shop_urls` → smoke H.3. Свой домен — чеклист **A-inf** В2.

### Сессия 2026-05-26 (В2 онбординг §3)

- ONBOARDING §3 «Заготовочный цех» — `[x]`; тесты 2/0; код без изменений.

### Сессия 2026-05-26 (В2 онбординг §2)

- ONBOARDING §2 «Точка продаж» — `[x]`; добавлено `address` в форму; тесты 5/0.

### Сессия 2026-05-26 (В2 онбординг §1)

- ONBOARDING_CHECKLIST §1 «Организация» — `[x]`; код без изменений; тесты onboarding org.

### Сессия 2026-05-26 (передача заказчику на живое демо)

- Стенд Fly проверен: `/up`, витрина A/B, логин barista.
- **Готово к H.3:** [`CUSTOMER_HANDOFF.md`](CUSTOMER_HANDOFF.md), UUID витрин в plain-доке и DEMO_LOGINS.
- H.0 smoke отмечен `[x]` в чеклисте; **H.3 живое демо** — ждёт заказчика.

### Сессия 2026-05-25 (handoff: В2 старт, В1 открыта в ops)

- Push **15 коммитов** В1 + **fix(deploy)** `4a25187`.
- Ops: папка `milestones/veha_1/` в git (`.gitignore`); CHANGELOG v1.50–v1.54.
- Живое демо: `LIVE_DEMO_SCENARIOS.md` + `LIVE_DEMO_SCENARIOS_PLAIN.md` (простой язык, URL витрин, роли gm/shift в словаре).
- **Не в git** на момент записи: `LIVE_DEMO_SCENARIOS*.md`, частично `CHECKLIST`/`README` — закоммитить при удобстве.

## Что сделано

- ✓ Архивирован старый docs-контур в `docs/archive/2026-05-11-reset` (без удаления истории).
- ✓ В `docs/product` оставлены только базовые: `01_Vision.md`, `02_functional.md`, `03_Business_Logic.md`.
- ✓ Создан `docs/product/core` и загружены 11 файлов ядра.
- ✓ Core-файлы переименованы по смыслу с сохранением индексов `01..11`.
- ✓ Добавлен `docs/product/core/README.md` (карта ядра).
- ✓ В `docs/agents/AGENTS.md` удалён блок «Воркфлоу задачи».
- ✓ Выполнено сравнение core SQL-доков с `db/schema.rb`.
- ✓ Размечены все 25 гэпов по статусам: `rename-only` / `missing-table`.
- ✓ Зафиксирован порядок батчей B0..B5 и анти-ошибочный чек-лист для каждого батча.
- ✓ Выполнен B1: добавлены `admin_audit_logs` и `feature_flags_logs` (миграция `20260511174500`).
- ✓ Прогон тестов после B1: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- ✓ Выполнен B2: добавлены `billing_plans`, `billing_subscriptions`, `tenant_invitations` + `tenants.plan_id` FK (миграция `20260511180000`).
- ✓ Прогон тестов после B2: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- ✓ Выполнен B3: добавлены `loyalty_accounts`, `loyalty_transactions`, `promo_code_usages`, `push_notifications`, `order_feedback` (миграция `20260511181500`).
- ✓ Прогон тестов после B3: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- ✓ Выполнен B3.5: добавлены `mobile_carts`, `mobile_payment_methods` (миграция `20260511183000`).
- ✓ Прогон тестов после B3.5: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- ✓ Выполнен B4: добавлены `pickup_calls`, `pickup_display_settings`, `pickup_events`; в `orders` добавлены `ready_at`, `issued_at`, `pickup_method` (миграция `20260511184500`).
- ✓ Прогон тестов после B4: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- ✓ Выполнен B5: `production_recipes`, `production_batches`, `supply_orders`, `supply_order_items`; расширение `ingredients` под production (миграция `20260511190000`).
- ✓ Прогон тестов после B5: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.

## Результат анализа core→schema

- Покрытие по таблицам (baseline до батчей): `37/62` (≈ `59.7%`).
- После B1–B5 с rename-mapping: **`62/62`** по целевому списку gap-таблиц.
- Расхождения:
  1. Нейминг (singular/plural, `*_log` vs `*_logs` и т.д.).
  2. Отсутствующие таблицы этапов 9-12 (billing/loyalty/pickup/production/push и смежные).
- Вывод: текущее состояние рабочее, но не полностью синхронизировано с 11-этапной core-моделью.

## Следующий шаг

**Веха 1:** H.2 + code review (`docs/operations/milestones/veha_1/CODE_REVIEW.md`, `docs/operations/milestones/veha_1/QA_ACCEPTANCE_RUN.md`).  
**Владелец:** апрув → коммит/деплой → H.3 демо → § I.

Чеклист и журнал В1: `docs/operations/milestones/veha_1/` ([README](milestones/veha_1/README.md)).

## Блокеры

Нет

## Заметки

Цель текущего этапа: строгое выравнивание реализации под 11 core-доков без разрушения рабочего контура. Тактика: маленькие обратимые батчи + тесты + smoke после каждого батча.

---

[2026-05-01 18:18] | Действие: Ужесточен протокол ведения состояния в `.cursor/rules/prd-factory-agent.mdc` (добавлен `Hard Persistence Gate`: fail-closed блокировка продолжения без обязательных записей в `SESSION_STATE/ISSUES/HANDOFF/CHANGELOG`; добавлен обязательный стартовый блок `last_done/current_state/next_step` для новых сессий). | Следующий шаг: Проверить соблюдение gate в следующей реальной задаче и подтвердить, что агент сначала обновляет операции-доки, затем продолжает. | Вопросы: нет.

[2026-05-01 19:30] | Действие: Создана миграция для добавления уникального индекса на key_hash в solid_cache_entries. Деплой выполнен. Миграция прошла успешно. Ошибка 500 на /shop/api/categories сохраняется. | Следующий шаг: Диагностировать почему SolidCache все еще падает. Проверить схему БД на production. | Статус: blocked | Вопросы: нет.

[2026-05-01 19:45] | Действие: Диагностирована проблема — Rack::Attack использует increment для rate limiting, но SolidCache не поддерживает это правильно. Добавлена конфигурация Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new. | Следующий шаг: Деплой исправления на production. | Статус: in_progress | Вопросы: нет.

[2026-05-01 19:50] | Действие: Деплой выполнен. Ошибка исправлена. /shop/api/categories теперь возвращает 401 (требуется авторизация) — это правильное поведение. | Следующий шаг: Нет | Статус: done | Вопросы: нет.
[2026-05-01 21:14] | Действие: Обновлено правило PRD Factory для ускорения и устранения конфликта записей: `SESSION_STATE` после каждого действия (кратко), `ISSUES` сразу при ошибке, `CHANGELOG/HANDOFF` батчем в конце логического шага; добавлено правило "PRD/ARCHITECTURE читать полно один раз за сессию". | Следующий шаг: Проверить правило на следующей задаче и подтвердить снижение количества лишних записей. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: Добавлена rake `shop:catalog:load` + `ALLOW_SHOP_CATALOG_LOAD` в `.env.example` для заливки каталога без полного seed. | Следующий шаг: Локально `bin/rails shop:catalog:load`; на Fly при необходимости с секретом ALLOW_SHOP_CATALOG_LOAD=1. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: Prod `/shop/api/categories` давал 500: Solid Cache пишет через `Rails.cache`, индекс для upsert должен быть на стороне cache-миграций + защита read/write кэша в `CategoriesController`. Добавлено `db/cache_migrate/20260502100000_ensure_solid_cache_key_hash_unique_index.rb`, `safe_cache_read/write`, `db/cache_schema.rb` обновлён. Деплой `fly deploy --no-cache`. Проверка: GET categories → HTTP 200. | Следующий шаг: При необходимости Resolve в Sentry для RUBY-3; мониторинг новых событий. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: PRD Factory режим C→B — глубокий аудит `prd-factory-agent.mdc` + `docs/agents/AGENTS.md`: 100 сценариев «триггер → ожидание → типичный сбой → рычаг усиления»; выявлено ключевое противоречие батч-записей (v10) vs «обновляй все ops-доки после каждого шага» (AGENTS). Отчёт пользователю в чате; файлы инструкций не менялись. | Следующий шаг: По явному go — точечные дополнения в `.cursor/rules/prd-factory-agent.mdc` и/или приписка приоритета в `AGENTS.md` без переписывания существующего смысла. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: По `go` пользователя — дополнения анти-игнор: `.cursor/rules/prd-factory-agent.mdc` (TL;DR срочность, приоритет операционки над AGENTS при конфликте, конец сессии HANDOFF+SESSION_STATE, git rewrite + Merge Conflict Gate, расширение Воркфлоу handoff’ами и mid-sprint); `docs/agents/AGENTS.md` — новые пункты без удаления старых. | Следующий шаг: Коммит при желании пользователя; соблюдение новых пунктов в следующих задачах. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: Инвентаризация «PRD в архиве»: в репозитории нет папки `docs/archive/` и нескольких версий продуктового PRD — канон один: `docs/product/PRD.md` + `docs/product/ARCHITECTURE.md` (оба короткие); рядом процессные `SPRINT_1_PROMPT.md`, `START.md`, AGENTS/pm/architect и т.д.; `CHANGELOG` v1.0 перечисляет создание канона; `docs/shop_api_auth.md` из старого CHANGELOG в дереве не найден. | Следующий шаг: Расширение PRD под онбординг точки — только после явного `go` и фиксации требований. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: Уточнение: в `docs/` не только `product/`+`operations/`+`agents/` — полный `cmd dir` показывает `ARCHIVE.md`, `features/` (в т.ч. `ADMIN_PANELS_LOGIN.md` — сценарии франчайзи/УК), `architecture/`, `guides/`, `prep-kitchen/`, `stack/`, `troubleshooting/`, `analysis/`, `sprint_24-04/`, `reviews/`, `project/`, `devdep/` и др. Отдельной папки `docs/archive/` нет; `docs/ARCHIVE.md` трактует весь `docs/` как архивный слой, канон в `docs/product/`. | Следующий шаг: по задаче — читать feature/architecture гиды, сверять с кодом (возможен drift). | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: По `go` — сформирован перечень вопросов для PRD (онбординг точки: кто жмёт, состав сущностей, роли/дубликаты franchise_manager, выдача пароля, канон URL shop/manager, каталог, MVP границы, идемпотентность, «своя БД» = RLS vs отдельный PG). Ответ в чате; `PRD.md` не менялся. | Следующий шаг: ответы пользователя/PM → внести в `docs/product/PRD.md` (или приложение) → затем `go` на архитектуру/реализацию. | Статус: done | Вопросы: см. чат 2026-05-02.

[2026-05-02] | Действие: Ответы заказчика по онбордингу внесены в `docs/product/PRD.md` (секция + глоссарий); `docs/operations/CHANGELOG.md` v1.9. | Следующий шаг: `go` на обновление `ARCHITECTURE.md` (поддомены, shop↔tenant, сервис онбординга) → реализация. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: По `go` выполнен Architect Pre-Feature шаг: `docs/product/ARCHITECTURE.md` дополнен секцией по онбордингу v1 (точка входа УК, состав сущностей, URL/поддомены, tenant/RLS, аудит, идемпотентность, границы v1). Обновлён `docs/operations/CHANGELOG.md` до v1.10. | Следующий шаг: `go` на Change Protocol — декомпозиция реализации по файлам/миграциям/тестам без кода в этом шаге. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: По `go` выполнен Change Protocol без кода: определены этапы реализации онбординга точки (сервис провижининга, контроллерный orchestration, поддоменный резолвер tenant, аудит, загрузка каталога на tenant, тесты интеграции и модели, rollout под feature flag). | Следующий шаг: `go` на реализацию Этапа 1 (сервис + минимальный wiring без миграций). | Статус: done | Вопросы: требуется подтвердить формат поддомена (slug org + slug address).

[2026-05-03] | Действие: По `go` реализован онбординг точки в УК: `Platform::TenantOnboarding::{Provision, CatalogBootstrap, UrlBuilder}`; create/update в транзакции с откатом при ошибке; автоматические PTS для активных продуктов; витрина резолвит tenant по поддомену (`SHOP_BASE_DOMAIN`, в проде по умолчанию coffeeos.fly.dev); flash со ссылкой на витрину; тесты + интеграция shop API по Host; `.env.example` — `SHOP_BASE_DOMAIN`. Миграций нет. | Следующий шаг: на Fly при необходимости wildcard DNS для `*.coffeeos.fly.dev`; полный `bin/rails test`. | Статус: done | Вопросы: нет.
[2026-05-11] | Действие: Зафиксирован Шаг 1 — `docs/operations/GAP_LIST_CORE_SCHEMA.md` (сравнение core->schema, покрытие 59.7%, список missing/extra, контроль ошибок на этапе gap-list, план Шага 2). | Следующий шаг: апрув пользователя на Шаг 2 (классификация `rename-only`/`missing-*`/`intentional`, затем батч-миграции с тестами). | Статус: done | Вопросы: нет.
[2026-05-11] | Действие: По апруву пользователя завершена классификация всех 25 гэпов в `docs/operations/GAP_LIST_CORE_SCHEMA.md`, добавлены статусы, батчи B0..B5 и чек-лист анти-ошибок (baseline, collisions, reversible migrations, test+smoke после каждого батча). | Следующий шаг: старт B0 (rename-only mapping), затем B1 с первой парой таблиц. | Статус: done | Вопросы: нет.
[2026-05-11] | Действие: Выполнен B1 — миграция `20260511174500_create_admin_audit_and_feature_flags_logs.rb` (таблицы `admin_audit_logs`, `feature_flags_logs`), миграции применены в dev и test окружениях, полный тестовый прогон зелёный (`324/1065`, без падений). | Следующий шаг: B2 (`billing_plans`, `billing_subscriptions`, `tenant_invitations`) по тому же safety-протоколу. | Статус: done | Вопросы: нет.
[2026-05-11] | Действие: Выполнен B2 — миграция `20260511180000_create_billing_and_tenant_invitations.rb` (таблицы `billing_plans`, `billing_subscriptions`, `tenant_invitations`; добавлен `tenants.plan_id` + FK), миграции применены в dev и test окружениях, полный тестовый прогон зелёный (`324/1065`, без падений). | Следующий шаг: B3 (`loyalty_accounts`, `loyalty_transactions`, `promo_code_usages`, `push_notifications`, `order_feedback`). | Статус: done | Вопросы: нет.
[2026-05-11] | Действие: Выполнен B3 — миграция `20260511181500_create_loyalty_promo_push_feedback.rb` (таблицы `loyalty_accounts`, `loyalty_transactions`, `promo_code_usages`, `push_notifications`, `order_feedback`), миграции применены в dev и test окружениях, полный тестовый прогон зелёный (`324/1065`, без падений). | Следующий шаг: B3.5 (`mobile_carts`, `mobile_payment_methods`) или B4 (`pickup_*`). | Статус: done | Вопросы: нет.
[2026-05-11] | Действие: Выполнен B3.5 — миграция `20260511183000_create_mobile_carts_and_payment_methods.rb` (таблицы `mobile_carts`, `mobile_payment_methods`), миграции применены в dev и test окружениях, полный тестовый прогон зелёный (`324/1065`, без падений). | Следующий шаг: B4 (`pickup_calls`, `pickup_display_settings`, `pickup_events`). | Статус: done | Вопросы: нет.
[2026-05-11] | Действие: Выполнен B4 — миграция `20260511184500_create_pickup_tables_and_orders_fields.rb` (таблицы `pickup_calls`, `pickup_display_settings`, `pickup_events`; поля `orders.ready_at`, `orders.issued_at`, `orders.pickup_method` + constraint/indexes), миграции применены в dev и test окружениях, полный тестовый прогон зелёный (`324/1065`, без падений). | Следующий шаг: B5 (`production_batches`, `production_recipes`, `supply_orders`, `supply_order_items`). | Статус: done | Вопросы: нет.

[2026-05-14] | Действие: Удалён `.cursor/rules/prd-factory-agent.mdc`. Переписан `.cursorrules` (верх: ISSUES сразу и до «решено», SESSION_STATE батчами, коммиты, продукт Vision/Functional/Business, ARCHITECTURE по готовности, деструктив только с явным «да»). Синхронизирован `docs/agents/AGENTS.md`; шапка `docs/operations/ISSUES.md`; `CHANGELOG.md` v1.20. | Следующий шаг: по необходимости — коммит ветки с этими правками. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Оценка практик Dodo; В1 — только Service Objects, без Domain Folders. Правила: `coffeeos-core.mdc` п.9, `coffeeos-services.mdc`, `AGENTS.md`. Журнал: `MILESTONE_PRACTICES.md`. Код не меняли. | Следующий шаг: апрув → батч приведения кода. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Добавлены unit-тесты prep_kitchen stock (3 файла) + health `TenantChecker`; прогон `test/services/` + platform tenants (86/0) и полный suite (337/0). `db:migrate` test для `20260520000001–02`. | Следующий шаг: апрув → сервис отмены заказа бариста; при необходимости — ISSUES на `MovementCreator` nested save. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: `Barista::OrderCancellationService` + тесты; контроллер `cancel` тонкий; fix `qty_change` и безопасное обновление остатка. Прогон barista tests 47/0. Чеклист VEHA_1 п. A отмена — [x]. | Следующий шаг: MovementCreator или следующий пункт чеклиста от пользователя. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: `MovementCreator` — transaction, movement create! затем items; тесты happy-path (10/0 stock). Чеклист VEHA_1 — [x]. | Следующий шаг: следующий пункт чеклиста от пользователя. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Аудит оркестрации в контроллерах — 3 новых сервиса (status update, payment callback, publish product). Чеклист A «пройти контроллеры» [x]. Тесты 75/0. | Следующий шаг: пункт B чеклиста от пользователя. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Полный `bin/rails test` после рефактора Service Objects (блок A): **347 runs, 1166 assertions, 0 failures**. Сводка «что/зачем» — `MILESTONE_PRACTICES.md` § «Рефактор Service Objects». Чеклист A полностью [x]. | Следующий шаг: блок B чеклиста. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Блок B — CRUD и связи MVP-моделей: `test/models/mvp_core_models_test.rb` (17 runs). Полный suite **364/1217/0**. Чеклист B первый ⭐ [x]. | Следующий шаг: демо-среда (2 точки, PTS, роли). | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Блок C — prep_kitchen_worker RBAC; `prep_kitchen_worker_rbac_test.rb` (6); полный suite **439/1644/0**. Чеклист C prep_kitchen_worker [x]. | Следующий шаг: platform/УК RBAC. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Блок **E спец-тесты** — `block_e_shop_flow_test.rb` (5), auth browser session; shop suite **57/147/0**. MCP и полный suite **не запускали**. | Следующий шаг: **апрув** → MCP DevTools shop → полный suite → `[x]`. | Статус: awaiting_mcp_approval | Вопросы: нет.

[2026-05-21] | Действие: Блок **E фаза 1** — Svelte shop: fix categories `{data}`, modifiers required/optional, mock «Оплатить», история `?today=1`, skeleton, double-click, cart modifiers, browser CSRF auth для same-origin `/shop`. Локально: `test/integration/shop/` + `test/services/shop/` **51/113/0**. | Следующий шаг: **апрув** → спец-тесты E → MCP → полный suite → `[x]`. | Статус: superseded | Вопросы: нет.

[2026-05-21] | Действие: Блок **D закрыт** — полный `bin/rails test` **455/1795/0**; fix тестов под глобальные `order_cancel_reasons` (Demo::EnvironmentSetup) + PTS assertions; чеклист D все `[x]`. | Следующий шаг: блок **E** (Shop Svelte). | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Критические фиксы D — movement form/params; миграция `20260523140000` (trigger `generate_order_number`); `Demo::EnvironmentSetup` (смена, cancel reasons, stock, stop-list reset); целевые тесты **42/206/0**. | Следующий шаг: **апрув** → `bin/rails test` → `[x]` блок D. | Статус: superseded | Вопросы: нет.

[2026-05-23] | Действие: Блок D — MCP **POST**-флоу 7 ролей (org/tenant/owner/open_as_manager; switch_tenant; GM price+staff; barista order+cancel; PK movement confirm/min_qty/stop-list; PK worker blocked). Подготовка: demo:seed + tmp/mcp_setup.rb + restart rails s. GET ранее OK. Полный suite **не запускали**. | Следующий шаг: **апрув** → `bin/rails test` → `[x]` блок D. | Статус: superseded | Вопросы: barista repeat order — исправлено v1.41.

[2026-05-23] | Действие: Блок D — Chrome DevTools MCP: 7 ролей, все GET-экраны OK; fix login email regex; dev db:migrate; smoke 7/84/0. POST-флоу не гоняли. Полный suite **не запускали** — ждём апрув. | Следующий шаг: апрув → `bin/rails test` → `[x]` блок D. | Статус: in_progress | Вопросы: нет.

[2026-05-21] | Действие: Блок D prep — `DEMO_LOGINS.md`, `test_login.rake`→`Demo::EnvironmentSetup`, чеклист D+MCP, `block_d_panel_screens_test` (7/84/0). MCP Chrome DevTools errored. Полный suite **не запускали** — ждём апрув. | Следующий шаг: апрув → `bin/rails test`; MCP visual flows. | Статус: superseded | Вопросы: включить MCP в Cursor Settings.

[2026-05-24] | Действие: Блок **G закрыт** — апрув на полный suite; `bin/rails test` **479/1896/0** (~286 s), ошибок/failures нет. Фиксы до прогона: `PortKiller`/`bin/ensure-server`, JS корзины barista, `normalize_cart_items`, `@shift` на create-order. MCP barista+shop OK. Чеклист G все `[x]`; `MILESTONE_PRACTICES` §G, `CHANGELOG` v1.48. | Следующий шаг: блок **H** — ручной QA `qa_scenarios.md`, живое демо. | Статус: done | Вопросы: нет.

[2026-05-25] | Действие: Push **16 коммитов** В1 на `develop`; Fly deploy fix (npm win32, v1.53). Доки живого демо: `LIVE_DEMO_SCENARIOS*.md`. Ops: `HANDOFF.md`, `CHANGELOG` v1.54. **В1 официально не закрыта** — параллельный старт **В2**. | Следующий шаг: агент **В2** по `HANDOFF.md`; В1 закрыть заочно (H.3 + §I). | Статус: veha2_active_veha1_open | Вопросы: закоммитить LIVE_DEMO в git при удобстве.
