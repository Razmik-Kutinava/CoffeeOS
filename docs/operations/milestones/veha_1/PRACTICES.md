# Веха 1 — практики и журнал (операционный)

Папка: `docs/operations/milestones/veha_1/`. Карта: [`README.md`](README.md).

Живой документ: сюда дописываем решения, статус внедрения и «где остановились».  
Продуктовый scope — `docs/product/development_roadmap.md` (без дублирования практик).

**Чеклист закрытия В1:** `docs/operations/milestones/veha_1/CHECKLIST.md` — основной рабочий документ; отмечать `[x]` по мере готовности.

### Gate: чеклист ↔ таск-трекер (не повторять «In Progress» при готовом коде)

1. **Источник решений** по смене/заказам: `docs/operations/milestones/veha_1/ORDER_ENTRY_AUDIT.md` (реестр входов + A/B).
2. **Закрытие блока G** — только после `[x]` «аудит входов» и «решение A/B» в `CHECKLIST.md` §G (эта папка).
3. **Таск-трекер** — статус Done **не раньше** соответствующих `[x]` в чеклисте.
4. **Новый канал заказа** — сначала строка в `docs/operations/milestones/veha_1/ORDER_ENTRY_AUDIT.md`, потом PR.

Правила кода для агентов: `.cursor/rules/coffeeos-services.mdc`, `coffeeos-core.mdc` п. 9, `docs/agents/AGENTS.md`.

---

## Веха 1 — Service Objects

**Статус (2026-05-21):** блок **A. Service Objects** в чеклисте закрыт. Полный прогон после рефактора: **347 runs, 1166 assertions, 0 failures**.  
**Не внедряем на В1:** Domain Folders (`app/models/{domain}`), запрет AR между «доменами» (практики Dodo — отложены).

### Что уже было в проекте до формализации правил

**Операционка / инфра (см. также `SESSION_STATE.md`, `CHANGELOG.md`):**

- Core-доки + gap-list → `schema.rb`; батчи **B1–B5** закрыты (`324` тестов, 0 failures).
- Онбординг точки: `Platform::TenantOnboarding::{Provision, CatalogBootstrap, UrlBuilder}`, поддомен витрины (`SHOP_BASE_DOMAIN`).
- Shop: `shop:catalog:load`, фиксы Solid Cache / Rack::Attack на categories API.
- Агент-процесс (2026-05-14): `.cursorrules` + `AGENTS.md`, без PRD Factory.
- Схема БД шире MVP В1 (loyalty, pickup, production…) — модели/сервисы под них частично.

**Код — сервисы уже есть (`app/services/`, 18 файлов):**

| Область | Сервисы | Тонкие контроллеры |
|--------|---------|-------------------|
| barista | `OrderCreationService`, `CartValidationService` | `orders#create` |
| shop | `OrderCreator`, `CartService`, `Catalog` | `api/orders`, `cart` |
| prep_kitchen | `Stock::Movement*`, `Reports::Builder`, `Queue::DemandCalculator`, `Incidents::Collector` | movements, reports, queue, incidents |
| platform | `TenantOnboarding::*`, `ProductImageStorage` | `tenants` create/update |
| health | `TenantChecker` | `health/tenants` |
| прочее | `AlertService` | — |

Тесты: `test/services/**` (13 файлов) + `test/controllers/platform/tenants_controller_test.rb`.

**Код — долг (цель после апрува):**

- ~~`barista/orders_controller` — отмена~~ → `OrderCancellationService` ✅.
- Склад v0.1: местами прямое изменение остатка (см. roadmap, Веха 3 — event log).
- manager/auth — в основном простые экраны, низкий приоритет.

### Решения по 7 практикам (из обсуждения Dodo)

| Практика | Веха | Статус |
|----------|------|--------|
| Service Objects | 1 | правила ✅ / рефактор A ✅ / полный test ✅ |
| Domain Folders | 2+? | отклонено для В1 |
| Outbox (Solid Queue) | 2 | не начато |
| Circuit Breaker | 2 (конец) | не начато |
| Event Sourcing склада | 3 | не начато (в roadmap) |
| Read Replicas | после нагрузки | не начато |
| Blameless Postmortems | 2 | не начато |

### Следующий шаг

Блок **G** — **закрыт**. **H.2** — **закрыт** (2026-05-25). **Git + Fly** — push develop, fix npm v1.53 (`4a25187`). **Веха 1 в ops не закрыта** (H.3, § I — `[ ]`). **Веха 2** — активная разработка параллельно (`docs/operations/HANDOFF.md`).

### H. Block H — QA приёмка — **H.2 закрыт** (2026-05-25)

**Документы:** `docs/agents/AGENTS/qa_scenarios.md` (сценарии + журнал), `docs/operations/milestones/veha_1/QA_ACCEPTANCE_RUN.md` (протокол).

**Этапы (агент):**

| Этап | Инструмент | Итог |
|------|------------|------|
| 1. Сухой | `bin/rails test` + integration auth/shop/block_f/block_g | **479 runs, 0 failures**; batch 36 runs — 1×429 flaky, изолированно OK |
| 2. MCP | Chrome DevTools | Shop: каталог → оплата → история; barista login; uk `/admin`; RBAC smoke |
| 3. Ручной + демо | Владелец | ⏳ не начат |

**MCP shop (2026-05-25):** tenant `8c7f5bc7-f2b4-43f0-991c-5ede0f480b20` — заказ mock accepted, история за сегодня OK.

**In-process `tmp/shop_mcp_flow.rb`:** 2/9 (401 на API без browser cookie) — не блокер; компенсировано MCP + integration shop.

**Не закрыто:** § H.3 живое демо; § I ops (формальное закрытие вехи).

### H.3 — передача заказчику (стенд готов) — **2026-05-26**

- Fly smoke: `/up`, витрина A/B (`tenant_id`), логин barista — OK.
- Одностраничник: `docs/operations/CUSTOMER_HANDOFF.md`.
- UUID витрин зафиксированы в `LIVE_DEMO_SCENARIOS_PLAIN.md`, `DEMO_LOGINS.md`.
- `fly certs` на `*.coffeeos.fly.dev` — ожидаемый отказ; режим B (`SHOP_URL_MODES.md`).
- **Ждём:** живое демо заказчиком (plain § 10) → `[x]` H.3 в чеклисте.

### H.3 — первый прогон заказчика (§ 1) — **2026-05-30**

- **Артефакт:** [`DEMO_FEEDBACK.md`](DEMO_FEEDBACK.md), PDF [`artifacts/customer_live_qa_block1_2026-05-30.pdf`](artifacts/customer_live_qa_block1_2026-05-30.pdf).
- **§ 1.2** — **OK**. **§ 1.1 / 1.3 / 1.4** — **частично** (см. таблицу в DEMO_FEEDBACK). Блокеров не заявлено.
- **H.3 `[ ]`:** §2–10 и 4 истории не сданы.

### H.3 — живое демо (инструкции готовы, прогон — владелец) — **2026-05-25**

| Документ | Назначение |
|----------|------------|
| `LIVE_DEMO_SCENARIOS_PLAIN.md` | Для заказчика и нетехнарей: шаги, логины, ссылки витрин |
| `LIVE_DEMO_SCENARIOS.md` | Техническая версия для QA/разработки |

**Витрины (Fly demo):** `bin/rails demo:shop_urls` — режим B. **Прод:** `{slug}.{SHOP_BASE_DOMAIN}/shop` — см. `docs/operations/SHOP_URL_MODES.md`.
**Минимум приёмки:** 4 истории в plain-доке § 10.

**MCP по ~55 сценариям** (`LIVE_DEMO_SCENARIOS.md`): только **после** живого демо (чеклист H.3 `[x]`); до живого — не гонять.

### Git / деплой — **2026-05-25**

- 15 коммитов В1 + `fix(deploy)` на `develop` → `origin`.
- CI: `.github/workflows/deploy.yml` → Fly; падение на `npm EBADPLATFORM` — исправлено в v1.53.

### Code review V1 (перед живым демо) — **2026-05-25**

**Протокол:** `docs/operations/milestones/veha_1/CODE_REVIEW.md`.

| CR | Суть | Статус |
|----|------|--------|
| CR-1 | N+1 `Product.find` в цикле `Shop::OrderCreator` | исправлено, тесты 51/0 |
| Остальное | гибрид смены, audit, RLS/RBAC, cancellation, MovementCreator | OK, без правок |

**Коммит/деплой:** сделано (`develop`, fix Fly npm).

---

### G. Block G — касса и смена — **закрыт** (2026-05-24)

**Решение:** гибрид — shop/киоск без смены; barista POS только с `CashShift.open`.

| Компонент | Поведение |
|-----------|-----------|
| Shop API | `cash_shift_id` = nil, смена не проверяется |
| Barista POST `/barista/orders` | без смены → redirect + alert |
| Barista cancel | без `reason` → отклонено; с reason → `AdminAuditLog` `order_cancelled` |
| `CashShift#close!` | `cash_difference` при недостаче (отрицательное значение) |

**Тесты (спец):** `block_g_cash_shift_test.rb` + `order_cancellation_service_test` — **12 runs, 59 assertions, 0 failures**.

**Полный suite (2026-05-24, после апрува):** `bin/rails test` — **479 runs, 1896 assertions, 0 failures, 0 errors, 0 skips** (~286 s). Ошибок во время прогона не было; только шум окружения (VIPS modules, DEPRECATION ActiveSupport::Configurable).

**Фиксы по ходу MCP / перед suite (не ломали suite):**

| Проблема | Исправление |
|----------|-------------|
| `:3001 connection refused` на Windows | `lib/port_killer.rb`, `bin/ensure-server` |
| Barista `addToCart is not defined` | JS корзины внутри `content_for` (`orders/new.html.erb`) |
| POST `cart_items[0][…]` → `NoMethodError: map` | `OrdersController#normalize_cart_items` + тест |
| Статус-бар «Смена закрыта» при открытой смене на create-order | `@shift = current_shift` в `orders#new` |

**MCP:** Chrome DevTools (2026-05-24) после `ruby bin/ensure-server` + `npm run vite:build`:

| Сценарий | Результат |
|----------|-----------|
| Barista, смена закрыта → POST заказ | **OK** — заказ не создан, редирект на create-order |
| Barista, смена открыта → оплата наличными | **OK** — `#202605-0003`, 295₽, дашборд |
| Shop `/shop?tenant_id=…` → корзина → mock оплата | **OK** — без смены, `cash_shift_id` nil |

**Инфра MCP:** `lib/port_killer.rb`, `bin/ensure-server`.

**Не в G:** `qa_scenarios.md` — блок **H**.

---

### F. Block F — Склад v0.1 — **закрыт** (2026-05-24)

**Списание при продаже:**
- `Inventory::OrderRecipeDeduction` — shop/barista, когда заказ сразу `accepted` (после order_items)
- DB-триггер `auto_deduct_ingredients_on_order_accept` — UPDATE `pending_payment` → `accepted` (callback оплаты)
- Migration `20260524140000`: снят `chk_stock_qty`, триггер `INSERT OR UPDATE`

**Отрицательный остаток (QA 4.2):** CHECK снят; validation модели `IngredientTenantStock` — `numericality: true` без `>= 0`. Ручные движения prep_kitchen по-прежнему блокируют минус в `MovementConfirmer`.

**Demo:** `Demo::EnvironmentSetup#ensure_demo_recipes_and_stock!` — ProductRecipe + IngredientTenantStock на точках A/B.

**Тесты:** `block_f_stock_flow_test.rb`, `order_recipe_deduction_test.rb`, `db_triggers_test`, `prep_kitchen_movements_test` — **14 runs, 47 assertions, 0 failures**.

**Техдолг В1 (норма, полный журнал — В3):**

| Место | Поведение | StockMovement? |
|-------|-----------|----------------|
| `Inventory::OrderRecipeDeduction` | прямой `IngredientTenantStock.update!` | **Нет** |
| DB-триггер `auto_deduct_*` | UPSERT `-qty` | **Нет** |
| `Barista::OrderCancellationService` | return movement при отмене preparing | **Да** (`return`) |
| `PrepKitchen::Stock::MovementConfirmer` | ручные приход/списание | **Да** (confirmed) |
| `Demo::EnvironmentSetup#reset_demo_pts_availability!` | `update_all` PTS sold_out | N/A |

---

### E. Block E — Shop Svelte — **закрыт** (2026-05-21)

**Среда:** `demo:seed` → `./bin/dev` (Rails :3001 + Vite) → `/shop?tenant_id=<demo-point-a uuid>`.

**Сделано (код):**

| Пункт чеклиста | Изменения |
|----------------|-----------|
| Меню + API | `catalog.js` — парсинг `{ data }`; skeleton на главной |
| Корзина + модификаторы | `modifiers.js` — `required`→radio; cart показывает `selected_modifiers`; busy на ±/удалить |
| Mock оплата | `Checkout.svelte` — кнопка «Оплатить», success без ЮKassa |
| История за сегодня | `orders#history?today=1`; UI «Заказы за сегодня» |
| Anti double-click | Product/Cart/Checkout — `adding`/`submitting`/`busyIndex` |
| Loader/skeleton | `PageSkeleton.svelte` — Catalog, Cart, Orders, CategoryProducts |

**Backend:** `orders_controller#history` — фильтр `today`; fix pagination `per_page`; `shop_api_auth` — browser CSRF session для same-origin `/shop`.

**Локальные тесты (фаза 1):** `test/integration/shop/` + `test/services/shop/` — **51 runs, 113 assertions, 0 failures**.

**Спец-тесты блока E (2026-05-21):** `test/integration/shop/block_e_shop_flow_test.rb` — меню `{data}`, корзина±модификаторы, mock оплата, history `today=1`, route `/shop`. + весь shop suite: **57 runs, 147 assertions, 0 failures**.

**MCP-прогон (2026-05-21 API + 2026-05-24 UI):** Chrome DevTools MCP — полный UI-флоу на `http://127.0.0.1:3001/shop?tenant_id=…`:

| Шаг | Результат |
|-----|-----------|
| Каталог (категории + плитки) | **OK** |
| Товар + модификаторы (radio/checkbox) | **OK** |
| Корзина (add, модификаторы в строке) | **OK** |
| Checkout + «Оплатить» (loader/disabled) | **OK** |
| Success + история за сегодня | **OK** (#7c379e4d, 295₽) |

In-process API: `tmp/shop_mcp_flow.rb` **9/9**. Shop suite **57/147/0**, полный **462/1834/0**.

**Dev-среда:** `.env` — `SHOP_API_KEY`, `SHOP_DEFAULT_TENANT_ID`; Vite — native bindings win32-arm64 (`npm install --force` на Windows ARM); `npm run vite:build` или `bin/dev`.

---

### D. Block D — журнал обхода панелей (2026-05-23, Chrome DevTools MCP)

**Среда:** `bin/rails db:migrate` (dev) → `demo:seed` → `rails s` на `127.0.0.1:3000`.  
**Логины:** `docs/operations/milestones/veha_1/DEMO_LOGINS.md`, пароль `demo123456`.  
**MCP:** Chrome DevTools — login (POST + CSRF) + fetch всех GET-экранов в isolated context на роль.

**Фикс по ходу:** `login_form_controller.js` — regex email для `*@demo.coffeeos.local` (multi-dot domain).

| Роль | Login | MCP GET | Результат |
|------|-------|---------|-----------|
| platform / УК | uk@demo.coffeeos.local | 9 экранов `/admin/*` | **OK** (title «CoffeeOS \| УК») |
| franchise_manager | franchise@demo.coffeeos.local | 12 экранов `/manager/*` | **OK** |
| shift_manager | shift-a@demo.coffeeos.local | 9 разрешённых + 4 запрещённых | **OK**; inventory/staff/devices/tv → redirect `/manager` |
| general_manager | gm-a@demo.coffeeos.local | 12 экранов incl. staff/new, tv_settings | **OK** |
| barista | barista-a@demo.coffeeos.local | 6 экранов `/barista/*` | **OK** |
| prep_kitchen_manager | pk-manager@demo.coffeeos.local | 9 экранов `/prep_kitchen/*` incl. movements/new | **OK** |
| prep_kitchen_worker | pk-worker@demo.coffeeos.local | 7 read-only; movements/new | **OK**; new → redirect `/movements` |

**MCP POST-флоу (2026-05-23, Chrome DevTools MCP, isolated context `post2-*`):**

**Подготовка dev:** `demo:seed` → **перезапуск** `rails s`. С v1.41: смена, cancel reasons и stock цеха — в `Demo::EnvironmentSetup`; `tmp/mcp_setup.rb` не нужен.

| Роль | MCP POST / PATCH | Результат |
|------|------------------|-----------|
| platform / УК | POST org → tenant (modules) → franchise_owner; POST `open_as_manager` → `/manager` | **OK** |
| franchise_manager | POST `switch_tenant` (→ B); GET menu без «Сохранить цену» | **OK** |
| general_manager | PATCH menu price (390 ₽); POST staff | **OK** |
| barista | POST order (cash); POST cancel `barista_cancel` | **OK**; повторный create — **исправлено v1.41** (миграция `20260523140000`, trigger `generate_order_number`) |
| prep_kitchen_manager | POST movement (items `[]` form) → confirm; PATCH min_qty; PATCH stop-list | **OK** (форма: `movement[items][][...]` + `scope: :movement`, v1.41) |
| prep_kitchen_worker | POST movement / PATCH min_qty → redirect; GET movements/new → `/movements` | **OK** (mutate заблокированы) |
| shift_manager | POST не требовался (GET + redirect inventory/staff/devices/tv) | **OK** (GET MCP 2026-05-23) |

**Заметки:** stop-list PATCH в MCP трогал PTS точки A — не смешивать с barista-order без снятия стоп-листа. `order_cancel_reasons` и открытая смена — в `Demo::EnvironmentSetup` (v1.41).

**Дубль smoke:** `block_d_panel_screens_test.rb` — **7/84/0** (2026-05-23).  
**Полный suite:** не запускали — ждём апрув.

### C. Platform / УК RBAC (2026-05-21)

| Доступ | Поведение |
|--------|-----------|
| **Разрешено** | `/admin` — org CRUD, tenant CRUD (`Provision` + modules), franchise_owner create, catalog menu, `open_as_manager` |
| **Выдача доступов** | `FranchiseOwnersController#create` → `franchise_manager` + `organization_id` |
| **Запрещено** | barista, general_manager, franchise_manager, prep_kitchen — redirect с `/admin` |
| **Мутации** | GM POST org/tenant/franchise_owner — redirect, сущности не создаются |

**Тесты:** `platform_uk_rbac_test.rb` — **7 runs**; `franchise_platform_admin_test.rb`; `platform/tenants_controller_test.rb`.  
**Полный прогон:** **446 runs, 1686 assertions, 0 failures**.

### C. Prep kitchen worker RBAC (2026-05-21)

| Доступ | Поведение |
|--------|-----------|
| **Разрешено (read)** | `/prep_kitchen`, queue, inventory, movements index |
| **Запрещено (mutate)** | min_qty, stop-list, movements create/confirm/cancel, `movements/new` |
| **Запрещено (panels)** | barista, manager, platform/admin |
| **Изоляция** | inventory только своего tenant |

**Тесты:** `prep_kitchen_worker_rbac_test.rb` — **6 runs**; `prep_kitchen_access_test.rb`.  
**Полный прогон:** **439 runs, 1644 assertions, 0 failures**.

### C. Prep kitchen manager RBAC (2026-05-21)

| Доступ | Поведение |
|--------|-----------|
| **Разрешено** | все `/prep_kitchen/*`; min_qty; stop-list; movements create/confirm/cancel |
| **Изоляция** | чужой tenant stock/movement — redirect, данные не меняются |
| **Запрещено** | barista, manager, platform/admin |

**Тесты:** `prep_kitchen_manager_rbac_test.rb` — **6 runs**; `prep_kitchen_access_test`, `prep_kitchen_movements_test`.  
**Полный прогон:** **433 runs, 1612 assertions, 0 failures**.

### C. Franchise manager RBAC (2026-05-21)

| Доступ | Поведение |
|--------|-----------|
| **Разрешено** | `/manager` + switch tenant в своей org; orders/reports/inventory/staff (просмотр/операции сети) |
| **Menu** | read-only (без формы «Сохранить цену»); `ProductTenantSettingPolicy#update?` — только GM/УК |
| **Запрещено** | barista, prep_kitchen, platform/admin; PATCH menu price; switch на чужую org |

**Fix:** `manager/menu/index.html.erb`, `product_tenant_setting_policy.rb`.  
**Тесты:** `franchise_manager_rbac_test.rb` — **6 runs**; `franchise_platform_admin_test.rb`.  
**Полный прогон:** **427 runs, 1577 assertions, 0 failures**.

### C. General manager RBAC (2026-05-21)

| Доступ | Поведение |
|--------|-----------|
| **Разрешено** | menu (PATCH price), inventory, staff (CRUD barista/shift/…), devices, reports — **своей** точки |
| **Изоляция** | PTS/inventory/staff/orders точки B в той же org — не видны и не мутируются |
| **Запрещено** | barista, prep_kitchen, platform/admin |
| **Staff** | не может назначить роль `general_manager` другому (см. `franchise_platform_admin_test`) |

**Тесты:** `test/integration/auth/general_manager_rbac_test.rb` — **9 runs**; `manager_office_panel_test.rb`.  
**Полный прогон:** **421 runs, 1544 assertions, 0 failures**.

### C. Shift manager RBAC (2026-05-21)

| Доступ | Поведение |
|--------|-----------|
| **Разрешено** | `/manager` — dashboard, orders, finance, shifts, reports, incidents; menu **read-only** |
| **Scope** | orders/payments/reports/incidents — только **текущая открытая** `CashShift` |
| **Запрещено** | inventory, staff, devices, tv settings; barista/prep_kitchen/admin; PATCH menu price |
| **История** | closed shift/order не в списках; direct URL closed order/shift → redirect |

**Тесты:** `test/integration/auth/shift_manager_rbac_test.rb` — **8 runs**; `manager_shift_panel_test.rb` — **5 runs**.  
**Полный прогон:** **412 runs, 1500 assertions, 0 failures**.

### C. Barista RBAC (2026-05-21)

| Доступ | Маршруты |
|--------|----------|
| **Разрешено** | `/barista` (dashboard, POS menu, shift, new order, history) |
| **Запрещено (redirect)** | `/manager/*` — menu, staff, reports, inventory, shifts, devices, tv settings |
| | `/prep_kitchen/*`, `/admin/*` |
| **Мутации** | PATCH menu price, POST staff — redirect, данные не меняются |
| **Tenant** | чужой order by id → redirect; history без чужих заказов |

**Тесты:** `test/integration/auth/barista_rbac_test.rb` — **7 runs** (+ `manager_office_panel_test` «barista denied /manager»).  
**Полный прогон:** **404 runs, 1457 assertions, 0 failures**.

### C. Session login — все панели (2026-05-21)

| Панель | Роль(и) | После `POST /login` |
|--------|---------|---------------------|
| `/barista` | barista | `barista_dashboard_path` |
| `/manager` | shift_manager, general_manager, franchise_manager | `manager_dashboard_path` (+ `manager_tenant_id` для franchise) |
| `/prep_kitchen` | prep_kitchen_manager, prep_kitchen_worker | `prep_kitchen_dashboard_path` |
| `/admin` | ук_global_admin | `platform_root_path` |

**Device token (не session):** `/tv_board?token=` — `test/integration/tv_board_test.rb`.

**Тесты:** `test/integration/auth/panel_login_test.rb` — **11 runs**; `test/controllers/auth/sessions_controller_test.rb` — **14 runs**.  
**Полный прогон:** **397 runs, 1414 assertions, 0 failures**.

### B. RLS — изоляция точек (2026-05-21)

**Ограничение:** новые Postgres-политики **не добавляем** (STOP-LIST roadmap). Проверяем существующие из миграций stage 1–5.

| Слой | Что проверяем | Как |
|------|---------------|-----|
| Postgres RLS | orders, payments, PTS, cash_shifts, ingredient_tenant_stocks | `SET LOCAL ROLE coffeeos_rls_test` + GUC `app.current_tenant_id` |
| Shop API | цены меню по `X-Shop-Tenant` | `test/integration/shop/api/tenant_isolation_test.rb` |
| App scope | `for_current_tenant`, HTTP barista | `test/integration/multi_tenant_isolation_test.rb` |

**Test infra:** `test/support/rls_test_bootstrap.rb` — replay `.up` существующих migrate (test DB из `schema.rb` без DDL политик); `rls_test_helper.rb`. Класс `RlsTenantIsolationTest` — `use_transactional_tests = false` (DDL не откатывается fixtures).

**Тесты RLS Postgres:** `test/integration/rls_tenant_isolation_test.rb` — **7 runs**.  
**Изоляция shop + app:** **9 runs** (2 + 7).  
**Полный прогон:** **386 runs, 1327 assertions, 0 failures**.

**Ручная проверка (dev):** `bin/rails rls:check`, `bin/rails rls:test_isolation`.

### B. Shop API (2026-05-21)

**Эндпоинты:** `GET categories`, `GET products`, `GET products/:id`, cart, `POST orders`, `GET orders/history`.

| Требование | Реализация |
|------------|------------|
| Меню | `Shop::Catalog` — Product + PTS точки; категории/цены/остаток |
| Карточка | `products#show` — описание + `modifier_groups` из УК |
| Авторизация | `X-Shop-Api-Key` = `ENV["SHOP_API_KEY"]` (в test отключено); categories#index — публичный |
| Tenant | `X-Shop-Tenant` / поддомен / `SHOP_DEFAULT_TENANT_ID` |
| Создание заказа | `Shop::OrderCreator` — корзина → Order + OrderItem + Payment |
| **Оплата В1** | **Имитация:** `SHOP_SIMULATE_PAYMENT=1` (default) — все методы → `accepted`/`succeeded`, provider `shop` |
| **Оплата В2** | `SHOP_SIMULATE_PAYMENT=0` — card/sbp → `pending_payment` до callback |

**Тесты:** `test/integration/shop/api/*`, `test/services/shop/*` — **62 runs**; полный suite **377 runs, 1293 assertions, 0 failures**.

**Fix:** `products#index` — default `per_page` (был limit 0).

### B. Демо-среда (2026-05-21)

**Запуск (dev/test):**
```bash
bin/rails demo:seed
# или db:seed (включает demo + каталог)
```

**Структура:**

| Сущность | Значение |
|----------|----------|
| Организация | `demo-coffeeos` — Demo CoffeeOS |
| Точка A | `demo-point-a` — Demo Coffee Point A |
| Точка B | `demo-point-b` — Demo Coffee Point B (+10 ₽ к base_price в PTS) |
| Заготовочный цех | `demo-prep-kitchen` — `production_kitchen`, модуль `prep_kitchen` |
| Каталог | `db/seeds_shop_catalog.rb` — 2 категории, 9 товаров, модификаторы |
| PTS | на точки A/B; bootstrap через `CatalogBootstrap` |

**Demo-пользователи** (пароль `demo123456`): полная таблица — **`docs/operations/milestones/veha_1/DEMO_LOGINS.md`**. Кратко:

| Email | Роль | Точка / вход |
|-------|------|--------------|
| uk@demo.coffeeos.local | ук_global_admin | A → `/admin` |
| franchise@demo.coffeeos.local | franchise_manager | org → `/manager` |
| barista-a@demo.coffeeos.local | barista | A → `/barista` |
| barista-b@demo.coffeeos.local | barista | B → `/barista` |
| gm-a@demo.coffeeos.local | general_manager | A → `/manager` |
| gm-b@demo.coffeeos.local | general_manager | B → `/manager` |
| shift-a@demo.coffeeos.local | shift_manager | A → `/manager` |
| pk-manager@demo.coffeeos.local | prep_kitchen_manager | цех → `/prep_kitchen` |
| pk-worker@demo.coffeeos.local | prep_kitchen_worker | цех → `/prep_kitchen` |

**Код:** `app/services/demo/environment_setup.rb`, `db/seeds_demo_v1.rb`, `lib/tasks/demo.rake`.  
**Тесты:** `test/services/demo/environment_setup_test.rb` — **3 runs, 29 assertions, 0 failures**.  
**Полный прогон:** **367 runs, 1246 assertions, 0 failures**.

### B. MVP-модели — CRUD и связи (2026-05-21)

**Проверено:** Tenant, Category, Product, ProductModifierGroup, ProductModifierOption, Order, OrderItem.

| Модель | CRUD | Связи | Замечания |
|--------|------|-------|-----------|
| Tenant | create/update | `organization`, `has_many :orders` | type/status через константы + predicate-методы |
| Category | create/update/destroy (пустая) | `has_many :products` | `restrict_with_error` — нельзя удалить с товарами |
| Product | create/update/destroy | `category`, `product_modifier_groups` | destroy → cascade групп и опций |
| ProductModifierGroup | create/update/destroy | `product`, `product_modifier_options` | CRUD в `platform/menu_controller` |
| ProductModifierOption | create/update/destroy | `group` | `price_delta >= 0` |
| Order | create/update/destroy | `tenant`, `order_items` | amounts consistency; dependent destroy items |
| OrderItem | create | `order`, snapshot `product_name`, jsonb `modifier_options` | `total_price = unit_price * quantity` |

**Тесты:** `test/models/mvp_core_models_test.rb` — **17 runs, 51 assertions, 0 failures**.  
**Полный прогон:** **364 runs, 1217 assertions, 0 failures**.

### Рефактор Service Objects — что сделано и зачем (2026-05-21)

Правила: `AGENTS.md`, `coffeeos-services.mdc`, `coffeeos-core` п.9 — оркестрация в `app/services/{панель}/`, контроллер тонкий, без Domain Folders.

| Изменение | Зачем | Файлы |
|-----------|--------|--------|
| **OrderCancellationService** | Отмена заказа = 4 сущности (order, log, audit, склад); не держать в контроллере | `app/services/barista/order_cancellation_service.rb` |
| Fix `qty` → `qty_change` | В контроллере был баг: поле `StockMovementItem` — `qty_change`, не `qty` | там же |
| Fix возврат остатка | Убран `update_all("qty = qty + #{...}")` — SQL-инъекция/правило проекта; lock + `update!` | там же |
| **MovementCreator** | Nested save падал: `belongs_to :movement` без id у items | `app/services/prep_kitchen/stock/movement_creator.rb` — сначала movement, потом items в transaction |
| **OrderStatusUpdateService** | Смена статуса POS + `OrderStatusLog` — один сценарий, один сервис | `app/services/barista/order_status_update_service.rb` |
| **PaymentStatusUpdater** | Callback оплаты: payment + log + перевод order в accepted — race в lock | `app/services/callbacks/payment_status_updater.rb` |
| **PublishProductService** | Создание/обновление товара УК + PTS на все точки с RLS `SET LOCAL` | `app/services/platform/menu/publish_product_service.rb` |
| Аудит контроллеров | Остальное уже в сервисах (create/cancel shop/barista, movements, onboarding) или тонкое (single-record, destroy category) | см. чеклист A |

**Новые тесты:** `order_cancellation_service_test`, `order_status_update_service_test`, `payment_status_updater_test`, `publish_product_service_test`, prep_kitchen stock (3), health tenant_checker.

**Не трогали:** `app/models/` структурой доменов, mass-refactor manager/auth, fiscal callback (одна запись).

### Журнал изменений (дописывать снизу)

- **2026-05-21** — зафиксированы правила агентов; инвентаризация кода; перенос журнала из roadmap в этот файл.
- **2026-05-21** — тесты Service Objects: добавлены `test/services/prep_kitchen/stock/{movement_creator,movement_confirmer,movement_canceller}_test.rb`, `test/services/health/tenant_checker_test.rb`. Прогон: `test/services/` + platform tenants — **86 runs, 0 failures**; полный `bin/rails test` — **337 runs, 1124 assertions, 0 failures**. Замечание: happy-path `MovementCreator` с nested items в unit-тесте не проходит валидацию «Stock movement items is invalid» — в новых тестах creator проверяет только валидации; confirmer/canceller собирают черновик через AR. Отдельно в ISSUES не заводили.
- **2026-05-21** — `Barista::OrderCancellationService`: отмена + аудит + возврат склада (preparing, `ingredients_used=false`). Исправлен баг: `StockMovementItem` с полем `qty_change` (было неверное `qty`), убран `update_all` с интерполяцией в SQL. Тесты: `order_cancellation_service_test.rb` (3), barista cancel integration — **47 runs barista**, 0 failures.
- **2026-05-21** — `PrepKitchen::Stock::MovementCreator`: save movement + items отдельно в transaction (fix nested validation). Тесты stock: **10 runs**, 0 failures; happy-path + hash items из формы.
- **2026-05-21** — Аудит контроллеров: вынесены `Barista::OrderStatusUpdateService`, `Callbacks::PaymentStatusUpdater`, `Platform::Menu::PublishProductService`. Тесты: **75 runs** (barista + callbacks + platform menu + controllers), 0 failures.
- **2026-05-21** — **Полный прогон после рефактора A:** `bin/rails test` → **347 runs, 1166 assertions, 0 failures**. Блок A чеклиста закрыт.
- **2026-05-21** — **B / MVP-модели:** добавлен `test/models/mvp_core_models_test.rb` — CRUD и связи Tenant → Category → Product → Modifier → Order → OrderItem. Прогон файла: **17/0**; полный suite: **364 runs, 1217 assertions, 0 failures**.
- **2026-05-21** — **B / Демо-среда:** `Demo::EnvironmentSetup` — 1 org, 2 точки, **заготовочный цех** `demo-prep-kitchen`, каталог shop, PTS, **9** demo-пользователей (в т.ч. `pk-manager` / `pk-worker` → prep_kitchen). `bin/rails demo:seed`.
- **2026-05-21** — **C / Prep kitchen worker RBAC:** read-only цех; мутации закрыты; `prep_kitchen_worker_rbac_test.rb` (6); полный suite **439/1644/0**.

---

## Веха 2

_(дописывать при старте: Outbox, Circuit Breaker, Postmortems, Domain Folders по необходимости)_

---

## Веха 3

_(дописывать при старте: Event Sourcing склада, Read Replicas, анти-фрод)_
