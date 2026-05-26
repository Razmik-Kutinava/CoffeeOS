# CHANGELOG

## v1.59 — 2026-05-26 (В2 онбординг §2: точка продаж)

- Поле `address` в форме создания точки УК (`platform/tenants`).
- Тесты: `onboarding_sales_point_test.rb` — 3 точки, модули, flash URL, меню, RLS (5/0).
- ONBOARDING_CHECKLIST §2 `[x]`; V2-T2 закрыт.

---

## v1.58 — 2026-05-26 (В2 онбординг §1: организация)

- Проверка ONBOARDING_CHECKLIST §1: создание org в УК (`/admin/organizations`), список, привязка tenant к org — **работает без правок кода**.
- Тесты: `test/integration/platform/onboarding_organization_test.rb` (3/0).
- Ops: `ONBOARDING_CHECKLIST.md` §1 `[x]`, журнал в `veha_2/PRACTICES.md`.

---

## v1.57 — 2026-05-26 (Fly: troubleshooting certs/SSH; полные Shop URL в demo:seed)

### Ops

- `FLY_DEMO_STAND.md`: разбор `fly certs` (ожидаемый отказ) и `fly ssh` timeout; как взять URL витрин **без SSH** (`fly logs`, УК).
- `demo:seed` печатает полные `https://coffeeos.fly.dev/shop?tenant_id=…` в лог release (APP_HOST).

---

## v1.56 — 2026-05-25 (URL витрины: режим Fly demo vs поддомены прод)

### Проблема

- `fly certs add "*.coffeeos.fly.dev"` и `demo-point-a.coffeeos.fly.dev` → `cannot register certificate for this domain` (зона `*.fly.dev` у Fly, нет DNS на `{slug}.coffeeos.fly.dev`).

### Решение (два режима, поддомены не отменены)

| Режим | Где | URL витрины |
|-------|-----|-------------|
| **A — прод** | Свой домен + `SHOP_BASE_DOMAIN` | `https://{slug}.shop.бренд.ru/shop` |
| **B — Fly demo** | `coffeeos`, без `SHOP_BASE_DOMAIN` | `https://coffeeos.fly.dev/shop?tenant_id=` |

- `UrlBuilder`: поддомены **только** при явном `SHOP_BASE_DOMAIN` (убран дефолт `coffeeos.fly.dev` в production).
- `fly.toml`: `SHOP_BASE_DOMAIN` не задан (комментарий про переход на режим A).
- `bin/rails demo:shop_urls` — печать URL всех активных точек.
- Доки: [`SHOP_URL_MODES.md`](SHOP_URL_MODES.md), обновлены `FLY_DEMO_STAND.md`, `INFRA_URLS.md`, `ONBOARDING.md`, чеклисты В1/В2.

### Твои действия после merge/deploy

1. Push `develop` → дождаться GitHub Actions → Fly.
2. `fly ssh console -a coffeeos -C 'bin/rails demo:shop_urls'` — скопировать URL витрин A/B.
3. Smoke: витрина A с `?tenant_id=`, логин barista (`DEMO_LOGINS.md`).
4. Свой домен — по чеклисту **A-inf** в `veha_2/CHECKLIST.md` и § «Переход B → A» в `SHOP_URL_MODES.md`.

---

## v1.55 — 2026-05-25 (Fly demo-стенд: автосид + docs в git)

### Fly / живое демо

- `fly.toml`: `SHOP_BASE_DOMAIN=coffeeos.fly.dev`, `DEMO_AUTO_SEED=true`, `release_command` = `db:prepare` + `demo:seed` (временно до закрытия H.3).
- `bin/docker-entrypoint`: запасной `demo:seed` при `DEMO_AUTO_SEED=true`.
- `docs/operations/FLY_DEMO_STAND.md` — инструкция, wildcard cert, откат автосида.
- Чеклист § **H.0** в `milestones/veha_1/CHECKLIST.md`, этап 0 в `QA_ACCEPTANCE_RUN.md`.

### Документация

- `.gitignore`: `docs/operations/**` и `milestones/**` в git (агенты + команда).
- Полный комплект `milestones/veha_2/` (чеклисты, онбординг, оплата, …).

---

## v1.54 — 2026-05-25 (параллельный старт В2; В1 **не закрыта** официально)

### Git / деплой

- **develop → origin:** 16 коммитов В1 (код A–G, тесты, docs product/ops/agents, `milestones/veha_1/` в git после правки `.gitignore`).
- **Fly:** первый деплой упал (`npm EBADPLATFORM`, win32 bindings) — **v1.53** исправлен; повторный push `4a25187`. Деплой через GitHub Actions `Deploy to Fly.io` на push в `develop`.
- **Прод:** https://coffeeos.fly.dev · витрина А https://demo-point-a.coffeeos.fly.dev/shop · Б https://demo-point-b.coffeeos.fly.dev/shop

### Документация (сессия 2026-05-25, конец В1)

- `docs/operations/milestones/veha_1/LIVE_DEMO_SCENARIOS.md` — ручные сценарии для технарей (все роли, 2–4 мин).
- `docs/operations/milestones/veha_1/LIVE_DEMO_SCENARIOS_PLAIN.md` — то же простым языком для заказчика/нетехнарей; ссылки на витрину, роли `gm-a`/`gm-b`/`shift-a` в словаре.
- Обновлены `CHECKLIST.md` § H.3, `README.md` (карта папки вехи).

### Код (уже в develop, кратко)

- Блоки A–G: сервисы barista/shop/inventory/demo, shop Svelte, block F/G тесты, RLS, гибрид смены, `OrderCancellationService`, `MovementCreator`, миграции stock/order_number.
- Code review: N+1 fix в `Shop::OrderCreator`.
- Deploy fix: `package.json` без win32 devDeps, `Dockerfile` → `npm ci`.

### Не закрыто (В1)

- **H.3** живое демо владельцем (инструкции готовы).
- **§ I** формальное закрытие вехи в ops.
- Локально **не в git** (на момент записи): `LIVE_DEMO_SCENARIOS*.md`, правки `CHECKLIST`/`README` — закоммитить перед В2.

### Следующий этап

- **Веха 2** — основная разработка (`HANDOFF.md`, `milestones/veha_2/`).
- **Веха 1** — остаётся открытой в ops до H.3 + § I; закрытие может быть заочным, без остановки В2.

---

## v1.53 — 2026-05-25

### Деплой Fly

- **Причина падения:** в `package.json` были прямые `devDependencies` только под Windows ARM64 (`@rolldown/binding-win32-arm64-msvc`, `@tailwindcss/oxide-win32-arm64-msvc`, `lightningcss-win32-arm64-msvc`) — `npm install` в Docker (linux/x64) падал с `EBADPLATFORM`.
- **Исправление:** убраны win32-binding из `package.json`; платформенные биндинги подтягивает Vite/Tailwind как optional. В Dockerfile — `npm ci`.
- **Локально на Windows:** после `npm install` optional-биндинги ставятся сами; не добавлять win32-пакеты в корень `package.json`.

---

## v1.52 — 2026-05-25

### Итог

- Документация **Вехи 1** собрана в `docs/operations/milestones/veha_1/`.
- Корневой `MILESTONE_PRACTICES.md` — указатель на папки вех.

### Структура

- `milestones/veha_1/`: CHECKLIST, PRACTICES, QA_ACCEPTANCE_RUN, CODE_REVIEW, ORDER_ENTRY_AUDIT, DEMO_LOGINS.
- `milestones/veha_2/` — заготовка под В2.

---

## v1.51 — 2026-05-25

### Итог

- Code review В1 перед демо: `docs/operations/milestones/veha_1/CODE_REVIEW.md`; блокеров нет.
- Исправление N+1 в `Shop::OrderCreator` (preload products).

### Тесты

- shop + block_g после правки: **51 runs, 165 assertions, 0 failures**.

---

## v1.50 — 2026-05-25

### Итог

- Gate **A/B гибрид смены**: `docs/operations/milestones/veha_1/ORDER_ENTRY_AUDIT.md`, §G чеклиста, gate в `MILESTONE_PRACTICES.md`.
- Сквозной аудит 8 входов заказа — все соответствуют В1.

### Документация

- `docs/operations/milestones/veha_1/ORDER_ENTRY_AUDIT.md` — реестр + правило синхронизации с таск-трекером.
- Комментарии в `Shop::OrderCreator`, `Barista::OrderCreationService` → ссылка на аудит.

---

## v1.49 — 2026-05-25

### Итог

- Блок **H.2** (агент): сухой прогон + MCP DevTools по `qa_scenarios.md`; журнал V1-* заполнен (Авто/MCP).
- Полный suite: **479 runs, 0 failures** (повторный прогон 2026-05-25).
- Живое демо (**H.3**) — на владельце.

### Документация

- `docs/agents/AGENTS/qa_scenarios.md` — этапы 1–3, журнал прогона.
- `docs/operations/milestones/veha_1/QA_ACCEPTANCE_RUN.md` — протокол прогона (сухой + MCP).

### Заметки QA

- `tmp/shop_mcp_flow.rb` in-process: 2/9 (401 без browser session); компенсировано MCP + `test/integration/shop/`.
- Batch shop+block_g: единичный 429 Rack::Attack; изолированный `block_g` shop test — OK.

---

## v1.48 — 2026-05-24

### Итог

- Блок **G закрыт**: гибрид shop без смены / barista только с открытой `CashShift`; отмена с причиной + audit; MCP UI OK.
- Полный suite: **479 runs, 1896 assertions, 0 failures** (2026-05-24).

### Изменено

- `Barista::OrderCreationService` — `shift.open?` guard.
- `Barista::OrderCancellationService` — обязательная причина.
- `Barista::OrdersController` — `normalize_cart_items`, `@shift` в `new`, cancel reason + rescue.
- `app/views/barista/orders/new.html.erb` — JS корзины внутри `content_for`.
- `lib/port_killer.rb`, `lib/dev_server.rb`, `bin/ensure-server` — MCP/dev на Windows.
- `test/integration/block_g_cash_shift_test.rb` — 8 runs (+ HTML form cart_items index).

---

## v1.47 — 2026-05-24

### Итог

- Блок **F закрыт**: списание по техкарте при продаже, отрицательный остаток, prep_kitchen movements, техдолг зафиксирован.
- `Inventory::OrderRecipeDeduction`, migration `block_f_stock_deduction`, demo recipes/stock.

### Изменено

- `app/services/inventory/order_recipe_deduction.rb` — новый.
- `Barista::OrderCreationService`, `Shop::OrderCreator` — вызов deduction.
- `IngredientTenantStock` — снят validation `qty >= 0`.
- `Demo::EnvironmentSetup` — `ensure_demo_recipes_and_stock!`.
- Тесты: `block_f_stock_flow_test.rb`, `order_recipe_deduction_test.rb`.

---

## v1.46 — 2026-05-24

### Итог

- Блок **E UI MCP закрыт**: Chrome DevTools — полный shop-флоу в браузере **OK**.
- Vite на Windows ARM: явные native bindings (`rolldown`, `tailwindcss/oxide`, `lightningcss`).
- `.env`: `SHOP_API_KEY` + `SHOP_DEFAULT_TENANT_ID` (demo-point-a).

---

## v1.45 — 2026-05-21

### Итог

- Блок **E закрыт**: MCP-эквивалент `tmp/shop_mcp_flow.rb` **9/9** на demo-point-a; shop suite **57/147/0**; полный suite **462/1834/0**.
- Chrome DevTools / Puppeteer MCP — **errored**; API-сценарии покрыты in-process runner + `block_e_shop_flow_test`.

### Изменено

- `tmp/shop_mcp_flow.rb` — CSRF bypass для dev-runner, API key header, fix status check.
- `docs/operations/milestones/veha_1/CHECKLIST.md` — блок E `[x]`.
- `docs/operations/MILESTONE_PRACTICES.md` — журнал MCP Block E.

---

## v1.44 — 2026-05-21

### Итог

- Блок **E спец-тесты**: `block_e_shop_flow_test.rb` + auth browser session; shop suite **57/147/0**.
- MCP и полный suite **не запускали** — ждём апрув.

### Изменено

- `test/integration/shop/block_e_shop_flow_test.rb` — новый.
- `test/integration/shop/api/authentication_test.rb` — browser CSRF session.

---

## v1.43 — 2026-05-21

### Итог

- Блок **E фаза 1**: Svelte shop — меню, корзина+модификаторы, mock оплата, история за сегодня, skeleton, anti double-click.
- Локальные shop-тесты: **51/113/0**. Полный suite **не запускали** — ждём апрув.

### Изменено

- Frontend: `catalog.js`, `api.js`, `modifiers.js`, `PageSkeleton.svelte`, Catalog/Cart/Checkout/Orders/Product/CategoryProducts.
- Backend: `orders_controller#history` (`today=1`), `shop_api_auth` browser session, layout `shop-api-key` meta.
- Тест: `orders_controller_test` — history today.

---

## v1.42 — 2026-05-21

### Итог

- Блок **D закрыт**: полный `bin/rails test` — **455 runs, 1795 assertions, 0 failures**.
- Fix тестов после `Demo::EnvironmentSetup` (глобальные `order_cancel_reasons`, shop-каталог в test DB).
- Чеклист `VEHA_1_CHECKLIST.md` § D — все 7 ролей `[x]`.

### Изменено

- `test/support/factories.rb` — `ensure_order_cancel_reason!`.
- Тесты: manager_office/shift, barista_tablet, catalog_bootstrap, publish_product_service.

---

## v1.41 — 2026-05-21

### Итог

- **Критические фиксы блока D:** форма movement (`movement[items][][...]`), триггер `generate_order_number`, `demo:seed` без `tmp/mcp_setup.rb`.
- Миграция `20260523140000_ensure_order_number_trigger` — функция + триггер + backfill пустых номеров.
- `Demo::EnvironmentSetup` — открытая смена demo-point-a, `order_cancel_reasons`, stock цеха, сброс stop-list.
- Целевые тесты: **42 runs, 206 assertions, 0 failures** (environment_setup, order_creation, prep_kitchen movements, movement_creator, block_d smoke).
- Полный suite **не запускали** — ждём апрув.

### Изменено

- `app/views/prep_kitchen/movements/new.html.erb` — `scope: :movement`, items `movement[items][][...]`.
- `app/controllers/prep_kitchen/movements_controller.rb` — `movement_params`, `normalize_items`.
- `app/services/barista/order_creation_service.rb` — `reload` + ошибка при пустом `order_number`.
- `app/services/demo/environment_setup.rb` — cancel reasons, open shift, kitchen stock, PTS reset.
- `db/migrate/20260523140000_ensure_order_number_trigger.rb` — новый.
- Тесты: `order_creation_service_test`, `environment_setup_test`, `prep_kitchen_movements_test`.

---

## v1.40 — 2026-05-23

### Итог

- Блок **D**: MCP **POST**-флоу всех 7 ролей (Chrome DevTools, isolated context).
- Подготовка dev: `demo:seed`, `tmp/mcp_setup.rb` (CashShift + `order_cancel_reasons`), restart `rails s`.
- Заметка: barista повторный create в dev — `idx_orders_tenant_number` (пустой `order_number`).
- Полный suite **не запускали** — ждём апрув.

### Изменено

- `MILESTONE_PRACTICES.md` § Block D — журнал POST-флоу.
- `SESSION_STATE.md`, `VEHA_1_CHECKLIST.md` — статус awaiting approval.

---

## v1.39 — 2026-05-23

### Итог

- Блок **D**: обход **7 ролей через Chrome DevTools MCP** — все GET-экраны OK.
- Fix: `login_form_controller.js` — email regex для `@demo.coffeeos.local`.
- Smoke: `block_d_panel_screens_test` **7/84/0**. Полный suite **не запускали**.

### Изменено

- `MILESTONE_PRACTICES.md` § Block D — журнал MCP-прогона.
- `app/javascript/controllers/login_form_controller.js` — multi-dot email domains.

---

## v1.38 — 2026-05-21

### Итог

- Подготовка блока **D**: единые demo-логины, чеклист с MCP, smoke GET всех панелей (**7 runs, 84 assertions, 0 failures**).
- Полный `bin/rails test` **не запускали** — ожидание апрува.

### Добавлено

- `docs/operations/milestones/veha_1/DEMO_LOGINS.md`
- `test/integration/panels/block_d_panel_screens_test.rb`

### Изменено

- `lib/tasks/test_login.rake` — делегирует `Demo::EnvironmentSetup` (убран `office_manager` и старые @test.com).
- `VEHA_1_CHECKLIST.md` §D — MCP + demo logins + порядок закрытия.

---

## v1.37 — 2026-05-21

### Итог

- Блок **C** чеклиста В1 закрыт: RBAC **platform / УК** — org, tenant, выдача `franchise_manager`, только `uk_global_admin`.
- Полный прогон: **446 runs, 1686 assertions, 0 failures**.

### Добавлено

- `test/integration/auth/platform_uk_rbac_test.rb` — 7 тестов.

### Документация

- `VEHA_1_CHECKLIST.md` — C platform/УК [x]; блок C завершён.
- `MILESTONE_PRACTICES.md` § Platform / УК RBAC.

---

## v1.36 — 2026-05-21

### Итог

- Блок **C** чеклиста В1: RBAC **prep_kitchen_worker** — просмотр своего цеха, без мутаций и чужих панелей.
- Полный прогон: **439 runs, 1644 assertions, 0 failures**.

### Добавлено

- `test/integration/auth/prep_kitchen_worker_rbac_test.rb` — 6 тестов.

### Документация

- `VEHA_1_CHECKLIST.md` — C prep_kitchen_worker [x]; `MILESTONE_PRACTICES.md` § Prep kitchen worker RBAC.

---

## v1.35 — 2026-05-21

### Итог

- Блок **C** чеклиста В1: RBAC **prep_kitchen_manager** — полный доступ к цеху, без чужих панелей.
- Полный прогон: **433 runs, 1612 assertions, 0 failures**.

### Добавлено

- `test/integration/auth/prep_kitchen_manager_rbac_test.rb` — 6 тестов.

### Документация

- `VEHA_1_CHECKLIST.md` — C prep_kitchen_manager [x]; `MILESTONE_PRACTICES.md` § Prep kitchen manager RBAC.

---

## v1.34 — 2026-05-21

### Итог

- Блок **C** чеклиста В1: RBAC **franchise_manager** — просмотр своих точек, без POS и редактирования меню.
- Полный прогон: **427 runs, 1577 assertions, 0 failures**.

### Изменено

- `ProductTenantSettingPolicy#update?` — franchise_manager не может менять цены.
- `manager/menu/index.html.erb` — форма цены только для general_manager / УК.

### Добавлено

- `test/integration/auth/franchise_manager_rbac_test.rb` — 6 тестов.

### Документация

- `VEHA_1_CHECKLIST.md` — C franchise_manager [x]; `MILESTONE_PRACTICES.md` § Franchise manager RBAC.

---

## v1.33 — 2026-05-21

### Итог

- Блок **C** чеклиста В1: RBAC **general_manager** — меню, цены, staff, склад своей точки.
- Полный прогон: **421 runs, 1544 assertions, 0 failures**.

### Добавлено

- `test/integration/auth/general_manager_rbac_test.rb` — 9 тестов: privileged paths, tenant isolation, forbidden panels.

### Документация

- `VEHA_1_CHECKLIST.md` — C general_manager [x]; `MILESTONE_PRACTICES.md` § General manager RBAC.

---

## v1.32 — 2026-05-21

### Итог

- Блок **C** чеклиста В1: RBAC **shift_manager** — оперативка текущей смены, без «глубокой» истории.
- Полный прогон: **412 runs, 1500 assertions, 0 failures**.

### Добавлено

- `test/integration/auth/shift_manager_rbac_test.rb` — 8 тестов: scope текущей смены, forbidden panels, menu read-only, closed shift hidden.

### Документация

- `VEHA_1_CHECKLIST.md` — C shift_manager [x]; `MILESTONE_PRACTICES.md` § Shift manager RBAC.

---

## v1.31 — 2026-05-21

### Итог

- Блок **C** чеклиста В1: RBAC **barista** — только POS и своя смена; manager/prep_kitchen/admin закрыты.
- Полный прогон: **404 runs, 1457 assertions, 0 failures**.

### Добавлено

- `test/integration/auth/barista_rbac_test.rb` — 7 тестов: allowed POS paths, forbidden panels, PATCH/POST guard, tenant isolation.

### Документация

- `VEHA_1_CHECKLIST.md` — C barista [x]; `MILESTONE_PRACTICES.md` § Barista RBAC.

---

## v1.30 — 2026-05-21

### Итог

- Блок **C** чеклиста В1: session-login для всех панелей (barista, manager, prep_kitchen, platform/УК).
- Полный прогон: **397 runs, 1414 assertions, 0 failures**.

### Добавлено

- `test/integration/auth/panel_login_test.rb` — 11 тестов: редиректы по ролям, guard без сессии, logout, user без ролей.

### Документация

- `VEHA_1_CHECKLIST.md` — C session login [x]; `MILESTONE_PRACTICES.md` § Session login.

---

## v1.29 — 2026-05-21

### Итог

- Блок **B** чеклиста В1: RLS — точка A не видит данные точки B; **новых Postgres-политик нет**.
- Полный прогон: **386 runs, 1327 assertions, 0 failures**.

### Добавлено

- `test/support/rls_test_bootstrap.rb`, `rls_test_helper.rb` — bootstrap существующих migrate-политик в test DB; роль `coffeeos_rls_test` (NOBYPASSRLS).
- `test/integration/rls_tenant_isolation_test.rb` — 7 тестов Postgres RLS (orders, payments, PTS, смены, остатки).

### Документация

- `VEHA_1_CHECKLIST.md` — RLS [x]; `MILESTONE_PRACTICES.md` § RLS.

---

## v1.28 — 2026-05-21

### Итог

- Блок **B** чеклиста В1: Shop API (меню, заказ, auth); **имитация оплаты** без шлюза (до вехи 2).
- Полный прогон: **377 runs, 1293 assertions, 0 failures**.

### Изменено

- `Shop::OrderCreator` — `SHOP_SIMULATE_PAYMENT=1` (default): все методы → accepted/succeeded; `=0` — режим pending для вехи 2.
- `Shop::Api::ProductsController#index` — fix default `per_page`.

### Добавлено

- Тесты: `shop/api/{products_controller,mvp_flow,authentication}_test.rb`.

### Документация

- `VEHA_1_CHECKLIST.md` — Shop API [x]; `MILESTONE_PRACTICES.md` § Shop API.

---

## v1.27 — 2026-05-21

### Итог

- Блок **B** чеклиста В1: демо-среда (1 org, 2 точки, каталог, PTS, пользователи с ролями).
- Полный прогон: **367 runs, 1246 assertions, 0 failures**.

### Добавлено

- `Demo::EnvironmentSetup` — идемпотентная демо-среда В1.
- `db/seeds_demo_v1.rb`, `lib/tasks/demo.rake` (`bin/rails demo:seed`).
- `test/services/demo/environment_setup_test.rb`.

### Изменено

- `db/seeds.rb` — вместо прямой загрузки каталога вызывает demo seed (каталог внутри setup).
- Демо: добавлен `demo-prep-kitchen` + `pk-manager` / `pk-worker` (prep_kitchen).

---

## v1.26 — 2026-05-21

### Итог

- Блок **B** чеклиста В1: проверены CRUD и связи MVP-моделей (Tenant, Category, Product, Modifier, Order, OrderItem).
- Полный прогон: **364 runs, 1217 assertions, 0 failures**.

### Добавлено

- `test/models/mvp_core_models_test.rb` — 17 тестов CRUD, ассоциаций, cascade/restrict, jsonb `modifier_options`.

### Документация

- `VEHA_1_CHECKLIST.md` — пункт B «MVP-модели» [x].
- `MILESTONE_PRACTICES.md` — таблица проверки моделей + журнал.

---

## v1.25 — 2026-05-21

### Итог

- Блок **A. Service Objects** чеклиста В1 закрыт.
- Полный прогон: **347 runs, 1166 assertions, 0 failures**.

### Документация

- `MILESTONE_PRACTICES.md` — таблица «Рефактор: что сделано и зачем».
- `VEHA_1_CHECKLIST.md` — все пункты секции A отмечены [x].

---

## v1.24 — 2026-05-21

### Добавлено

- `Barista::OrderStatusUpdateService`, `Callbacks::PaymentStatusUpdater`, `Platform::Menu::PublishProductService` + unit-тесты.

### Изменено

- `barista/orders_controller#update_status`, `callbacks/events_controller#payment`, `platform/menu_controller` create/update product.
- `docs/operations/milestones/veha_1/CHECKLIST.md` — аудит контроллеров [x].

### Проверка

- `bin/rails test test/services/barista/ test/services/callbacks/ test/services/platform/menu/ test/controllers/callbacks/events_controller_test.rb test/controllers/barista/orders_controller_test.rb` → 75 runs, 0 failures.

---

## v1.23 — 2026-05-21

### Изменено

- `app/services/prep_kitchen/stock/movement_creator.rb` — создание черновика: сначала `StockMovement`, затем `stock_movement_items` в транзакции (вместо nested save).
- `test/services/prep_kitchen/stock/movement_creator_test.rb` — happy-path и hash items из формы.

### Проверка

- `bin/rails test test/services/prep_kitchen/stock/` → 10 runs, 0 failures.

### Изменено (docs)

- `docs/operations/milestones/veha_1/CHECKLIST.md` — MovementCreator [x].

---

## v1.22 — 2026-05-21

### Добавлено

- `app/services/barista/order_cancellation_service.rb` — отмена заказа, `OrderStatusLog`, `AdminAuditLog`, возврат склада при `preparing` + `ingredients_used=false`.
- `test/services/barista/order_cancellation_service_test.rb`.

### Изменено

- `app/controllers/barista/orders_controller.rb` — `#cancel` вызывает сервис.
- `docs/operations/milestones/veha_1/CHECKLIST.md` — пункт отмена [x].

### Проверка

- `bin/rails test test/services/barista/ test/controllers/barista/orders_controller_test.rb` → 47 runs, 0 failures.

---

## v1.21 — 2026-05-21

### Добавлено

- `test/services/prep_kitchen/stock/movement_creator_test.rb` — валидации `MovementCreator`.
- `test/services/prep_kitchen/stock/movement_confirmer_test.rb` — подтверждение черновика, отрицательный остаток.
- `test/services/prep_kitchen/stock/movement_canceller_test.rb` — отмена черновика.
- `test/services/health/tenant_checker_test.rb` — структура чеков и касса.

### Проверка

- `PARALLEL_WORKERS=0 bin/rails test test/services/ test/controllers/platform/tenants_controller_test.rb` → 86 runs, 0 failures.
- `PARALLEL_WORKERS=0 bin/rails test` → 337 runs, 1124 assertions, 0 failures.

### Изменено

- `docs/operations/MILESTONE_PRACTICES.md`, `SESSION_STATE.md` — журнал прогона тестов Service Objects.

---

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
