# Веха 1 — чеклист закрытия «Цифровой прилавок»

**Цель:** рабочий демо-прототип одной кофейни, online-only.

**Статус вехи:** код A–G и H.2 готовы; **официальное закрытие — нет** (§ H.3, § I ниже `[ ]`). Разработка **Вехи 2** идёт параллельно.

**Не входит в В1:** offline, Event Sourcing склада, новые RLS-политики, Domain Folders, Outbox, Flutter/киоск, loyalty/pickup/production как продукт для демо.

**Как пользоваться:** отмечай `[x]` по мере выполнения. Закрытие вехи — когда критичные пункты (⭐) сделаны и зафиксирован блок «Закрытие вехи» внизу.

**Связанные доки:** [`README.md`](README.md) (карта папки), [`PRACTICES.md`](PRACTICES.md) (журнал), `docs/product/development_roadmap.md`, `docs/agents/AGENTS/qa_scenarios.md`.

### ⚠️ Gate: чеклист ↔ таск-трекер (обязательно)

- **Решение A/B и аудит входов заказа** — только `docs/operations/milestones/veha_1/ORDER_ENTRY_AUDIT.md` + §G ниже.
- В Linear/Jira **не ставить Done**, пока в этом чеклисте нет `[x]` на тот же пункт.
- **Новый канал заказа** (shop, kiosk, API) → сначала строка в `docs/operations/milestones/veha_1/ORDER_ENTRY_AUDIT.md`, потом код.

---

## A. Service Objects (практика В1)

- [x] Правила агентов: `.cursor/rules/coffeeos-core.mdc` п.9, `coffeeos-services.mdc`, `docs/agents/AGENTS.md`
- [x] Автотесты: `test/services/**` + полный `bin/rails test` зелёный (зафиксировать дату/число runs в `MILESTONE_PRACTICES.md`)
- [x] ⭐ Вынести **отмену заказа бариста + возврат на склад** в `Barista::OrderCancellationService` (`app/services/barista/order_cancellation_service.rb`)
- [x] ⭐ Починить **`PrepKitchen::Stock::MovementCreator`** — черновик + позиции в транзакции (movement `create!`, затем items)
- [x] Пройти контроллеры/критичные экшены → сервисы (без Domain Folders): `OrderStatusUpdateService`, `PaymentStatusUpdater`, `PublishProductService`; ранее — create/cancel/movements/shop/onboarding. **Оставлено в контроллерах (тонко):** `platform/tenants` (обёртка Provision), `menu#destroy_category`, fiscal callback, manager/tv single-record
- [x] После рефактора — повторный прогон `bin/rails test` (**2026-05-21:** 347 runs, 0 failures)

**Что это значит:** тяжёлая логика не в контроллерах; модели общие в `app/models/`; панель в пути сервиса (`barista`, `shop`, `prep_kitchen`, `platform`).

---

## B. Backend и данные

- [x] ⭐ Проверить CRUD и связи MVP-моделей: Tenant, Category, Product, Modifier (группы/опции), Order, OrderItem — **2026-05-21:** `test/models/mvp_core_models_test.rb` (17 runs); CRUD + ассоциации + cascade/restrict; полный suite **364 runs, 0 failures**
- [x] ⭐ Демо-среда: организация + точки (сейчас: **1 организация, 2 точки**), каталог, **ProductTenantSetting** (цены), пользователи с ролями — **2026-05-21:** `Demo::EnvironmentSetup`, `bin/rails demo:seed`; org `demo-coffeeos`; точки `demo-point-a/b`; **цех** `demo-prep-kitchen`; PTS (B = base+10₽); **9** demo-пользователей (в т.ч. prep_kitchen manager/worker → `/prep_kitchen`)
- [x] ⭐ Shop API: меню + создание заказа + авторизация; **реальной оплаты нет** — каталог и карточки задаются из **админки УК** — **2026-05-21:** endpoints `/shop/api/{categories,products,orders,cart}`; auth `X-Shop-Api-Key`; меню из Product+PTS+modifiers (УК); **В1 имитация оплаты** `SHOP_SIMULATE_PAYMENT=1` (default) → order `accepted`; шлюз — **веха 2** (`SHOP_SIMULATE_PAYMENT=0`); тесты shop **62 runs**; полный suite **377 runs, 0 failures**
- [x] RLS: точка А не видит данные точки Б; **новые политики Postgres не добавлять** (STOP-LIST roadmap) — **2026-05-21:** Postgres RLS под ролью `coffeeos_rls_test` (NOBYPASSRLS); bootstrap **существующих** миграций политик в test DB; `test/integration/rls_tenant_isolation_test.rb` (7 runs) + shop/app isolation; полный suite **386 runs, 0 failures**
- [x] Онбординг точки в УК: `Platform::TenantOnboarding::Provision`, поддомен витрины (`SHOP_BASE_DOMAIN`)
- [ ] QA 5.1 (позже, ручной): ошибка на последнем шаге онбординга → полный откат транзакции

---

## C. Auth и роли (`docs/product/02_functional.md` §5)

- [x] ⭐ Token/session login для всех панелей стабилен — **2026-05-21:** `POST /login` → session; редиректы barista/manager/prep_kitchen/admin; logout; `test/integration/auth/panel_login_test.rb` (11 runs) + `sessions_controller_test` (14); TV — device_token (`tv_board_test`); полный suite **397 runs, 0 failures**
- [x] ⭐ **barista** — только POS и своя смена; нет меню точки, staff, аналитики, настроек (403/редирект) — **2026-05-21:** POS `/barista/*` + своя смена; редирект с `/manager/*` (menu, staff, reports, inventory, shifts, devices, tv), `/prep_kitchen`, `/admin`; PATCH menu/staff запрещён; чужой tenant order — redirect; `test/integration/auth/barista_rbac_test.rb` (7 runs); полный suite **404 runs, 0 failures**
- [x] ⭐ **shift_manager** — оперативка за текущий день; нет «глубокой» истории — **2026-05-21:** `/manager` orders/finance/shifts/reports/incidents — только **текущая открытая** cash shift; menu read-only; inventory/staff/devices/tv/barista/prep_kitchen/admin — redirect; closed shift/order скрыты; `shift_manager_rbac_test` (8) + `manager_shift_panel_test` (5); полный suite **412 runs, 0 failures**
- [x] ⭐ **general_manager** — меню, цены, staff, склад **своей** точки — **2026-05-21:** menu/inventory/staff/devices/reports своей точки; PATCH цены; POST staff; изоляция от точки B (org); barista/prep_kitchen/admin — redirect; `general_manager_rbac_test` (9) + `manager_office_panel_test`; полный suite **421 runs, 0 failures**
- [x] ⭐ **franchise_manager** — просмотр своих точек; **нет** POS и редактирования меню — **2026-05-21:** switch tenant в org; menu read-only; PATCH цены → Pundit redirect; barista/prep_kitchen/admin закрыты; fix policy+UI; `franchise_manager_rbac_test` (6) + `franchise_platform_admin_test`; полный suite **427 runs, 0 failures**
- [x] ⭐ **prep_kitchen_manager** (`prep_kitchen_manager`, «Менеджер заготовочного цеха») — вход → `/prep_kitchen`; остатки, движения (черновик/подтверждение/отмена), stop-list, min_qty, отчёты **своего** цеха; **нет** POS, `/manager`, `/barista`, `/admin` (403/редирект) — **2026-05-21:** все экраны `/prep_kitchen/*`; min_qty/stop-list/movements CRUD; tenant isolation; barista/manager/admin redirect; `prep_kitchen_manager_rbac_test` (6) + `prep_kitchen_access/movements_test`; полный suite **433 runs, 0 failures**
- [x] ⭐ **prep_kitchen_worker** (`prep_kitchen_worker`, «Работник заготовочного цеха») — вход → `/prep_kitchen`; просмотр остатков/очереди **своего** цеха; **нет** POST/PATCH движений, stop-list, min_qty, manager/barista/platform экранов (403/редирект) — **2026-05-21:** dashboard/queue/inventory/movements read-only; мутации redirect; tenant isolation; `prep_kitchen_worker_rbac_test` (6) + `prep_kitchen_access_test`; полный suite **439 runs, 0 failures**
- [x] ⭐ **platform / УК** — создание организации и точки, выдача доступов — **2026-05-21:** `/admin` только `uk_global_admin`; CRUD org/tenant (Provision+modules); franchise_owner → `franchise_manager`; `open_as_manager`; barista/GM/franchise_manager — redirect; GM POST org — redirect; `platform_uk_rbac_test` (7) + `franchise_platform_admin_test`, `platform/tenants_controller_test`; полный suite **446 runs, 0 failures**

---

## D. Внутренние панели (Rails + Hotwire)

**C** = RBAC (integration-тесты). **D** = UI/флоу **ещё раз** через **Chrome DevTools MCP** (быстрый обход экранов + ключевые действия). Логины: `docs/operations/milestones/veha_1/DEMO_LOGINS.md` (`demo123456`). Закрытие `[x]`: журнал обхода в `MILESTONE_PRACTICES.md` § Block D → **апрув** → `bin/rails test`.

**Порядок:** роль за ролью MCP → фикс багов → ops-журнал → апрув → полный test suite → `[x]`.

- [x] ⭐ **platform / УК** — `uk@demo.coffeeos.local` → `/admin` — **2026-05-21:** MCP GET+POST OK; полный suite **455/1795/0**
  - MCP GET: dashboard; organizations (index/new/edit); tenants (index/new/edit); franchise_owners/new; menu
  - MCP флоу: org → tenant (modules) → franchise_owner; правка каталога; open_as_manager → manager

- [x] **franchise_manager** — `franchise@demo.coffeeos.local` → `/manager` — **2026-05-21:** MCP GET+POST OK
  - MCP GET: dashboard; orders; finance×3; shifts; reports; inventory; menu; staff; devices; incidents
  - MCP флоу: switch_tenant (A↔B); menu read-only (нет формы цены)

- [x] **shift_manager** — `shift-a@demo.coffeeos.local` → `/manager` — **2026-05-21:** MCP GET OK
  - MCP GET: dashboard; orders (+show); finance×3; shifts (+show, close); reports; incidents; menu
  - MCP флоу: только открытая смена; inventory/staff/devices/tv — redirect

- [x] **general_manager** — `gm-a@demo.coffeeos.local` → `/manager` — **2026-05-21:** MCP GET+POST OK
  - MCP GET: dashboard; menu; inventory; staff (index/new/edit); devices; reports; orders/finance/shifts/incidents
  - MCP флоу: PATCH цена PTS; POST staff; данные только точки A

- [x] ⭐ **barista** — `barista-a@demo.coffeeos.local` → `/barista` — **2026-05-21:** MCP GET+POST OK; fix order_number trigger v1.41
  - MCP GET: dashboard; menu; create-order; order show; shift; orders/history; reports
  - MCP флоу: заказ → оплата/имитация → history; отмена с причиной

- [x] ⭐ **prep_kitchen_manager** — `pk-manager@demo.coffeeos.local` → `/prep_kitchen` — **2026-05-21:** MCP GET+POST OK; fix movement form v1.41
  - MCP GET: dashboard; queue; inventory; movements (index/new); stop_list; recipes; incidents; reports
  - MCP флоу: черновик movement → confirm; stop-list; min_qty

- [x] **prep_kitchen_worker** — `pk-worker@demo.coffeeos.local` → `/prep_kitchen` — **2026-05-21:** MCP GET+POST OK
  - MCP GET: dashboard; queue; inventory; movements (index); recipes; incidents; reports
  - MCP флоу: только просмотр; new movement / min_qty / stop-list — redirect или disabled

**Автопроверка (дубль):** `test/integration/panels/block_d_panel_screens_test.rb` — **7/84/0**  
**MCP-прогон:** 2026-05-23 GET+POST все 7 ролей OK (`MILESTONE_PRACTICES.md` § Block D). Фиксы v1.41: movement form, order_number trigger, demo:seed. Полный suite **455 runs, 1795 assertions, 0 failures** — **2026-05-21**.

---

## E. Витрина Shop (Svelte, `app/frontend`)

**Статус (2026-05-21):** MCP-прогон + полный suite **462/1834/0** — **закрыт**.

- [x] ⭐ Меню: категории + плитки товаров с API
- [x] ⭐ Корзина: add/remove, **один уровень** модификаторов
- [x] ⭐ «Оплатить» — имитация транзакции (без платёжного шлюза)
- [x] ⭐ История заказов за сегодня
- [x] Защита от двойного клика на оплате (loader / disable)
- [x] Лоадер/скелетон при медленном ответе (не пустой экран)

**MCP-прогон:** 2026-05-21 — API in-process **9/9**; **Chrome DevTools MCP UI 2026-05-24** — каталог → товар+модификаторы → корзина → mock оплата → история за сегодня **OK**; shop suite **57/147/0**; полный suite **462/1834/0**.

---

## F. Склад v0.1 (упрощённо, не Event Sourcing)

**Статус (2026-05-24):** спец-тесты **14/47/0**; полный suite **470/1854/0**.

- [x] ⭐ При продаже остаток в `ingredient_tenant_stocks` уменьшается по техкарте (`product_recipes`)
- [x] ⭐ Допуск **отрицательного** остатка — продажа не блокируется (QA 4.2)
- [x] ⭐ prep_kitchen: черновик `StockMovement` → подтверждение меняет остаток
- [x] Зафиксировать в техдолг (operations): места с прямым `update_all` / изменением остатка **без** строки движения (норма для В1, полный журнал — В3)

**Реализация:** `Inventory::OrderRecipeDeduction` (shop/barista INSERT accepted) + DB-триггер `auto_deduct` (UPDATE→accepted); migration сняла `chk_stock_qty`; demo seed — техкарты на точках A/B.

---

## G. Касса и смена

**Статус (2026-05-24):** **закрыт.** Спец-тесты **12/59/0**; MCP UI OK; полный suite **479/1896/0**.

### Решение В1 — **гибрид**

| Канал | Смена | Заказ без открытой смены |
|-------|-------|---------------------------|
| **Shop** (витрина `/shop`) | не нужна | **Разрешён** |
| **Киоск** (когда появится) | не нужна | **Разрешён** |
| **Бариста POS** (`/barista`) | обязательна | **Запрещён** (вариант B) |

Смена на точке: открытие/закрытие, привязка заказов баристы к `cash_shift_id`, выручка по смене.

**Сделано (код, 2026-05-24):** гибрид; `OrderCreationService` — guard `shift.open?`; отмена — обязательная `reason` + `AdminAuditLog`; `CashShift#close!` → `cash_difference` (недостача); `normalize_cart_items`, JS корзины, `bin/ensure-server`.

- [x] ⭐ **Решение A/B зафиксировано:** гибрид В1 (shop/киоск без смены, barista со сменой); В2 — единый запрет → `docs/operations/milestones/veha_1/ORDER_ENTRY_AUDIT.md`
- [x] ⭐ **Сквозной аудит входов заказа** (**2026-05-25:** реестр 8 входов, все OK) — `docs/operations/milestones/veha_1/ORDER_ENTRY_AUDIT.md`
- [x] ⭐ Гибрид закреплён в коде + тесты (barista B, shop/киоск без смены)
- [x] ⭐ Отмена заказа / позиции с **причиной** и записью в `admin_audit_logs` (QA 3.2)
- [x] Сверка смены при закрытии (недостача) — `close!`, тест shortage; полный анти-фрод — В3

---

## H. QA и приёмка

**Порядок:** в конце вехи, после закрытия блоков A–G. Сначала доки = код, потом сценарии, потом прогон и фиксы.

### 1. Синхронизация документации (итоги В1)

Привести в соответствие с **реально сделанным** в A–G (без выдуманных фич):

| Документ | Что проверить / дописать |
|----------|---------------------------|
| `docs/product/01_Vision.md` | scope В1, что в демо, что отложено |
| `docs/product/02_functional.md` | роли, shop/barista/склад/смена (гибрид) |
| `docs/product/03_Business_Logic.md` | смена, заказ, списание, отмена с причиной |
| `docs/product/development_roadmap.md` | В1 закрыта / хвосты в В2–В3 |
| `docs/product/ARCHITECTURE.md` | при расхождении с кодом — точечно |
| `docs/agents/AGENTS/qa_scenarios.md` | новые сценарии E/F/G и правки старых |

- [x] ⭐ Продуктовые доки + roadmap согласованы с кодом В1 (**2026-05-24:** `01_Vision`, `02_functional`, `03_Business_Logic`, `development_roadmap`, `ARCHITECTURE`)
- [x] ⭐ `qa_scenarios.md` дополнен под В1 (**2026-05-25:** сценарии V1-*, этапы Авто/MCP/Ручной, журнал)

### 2. Прогон и фиксация

- [x] ⭐ Прогон сценариев V1 — **этап 1 сухой** + **этап 2 MCP** (**2026-05-25**, протокол `docs/operations/milestones/veha_1/QA_ACCEPTANCE_RUN.md`, журнал в `qa_scenarios.md`)
- [x] Баги по прогону: критичных FAIL нет (1×429 Rate Limit в batch — flaky; изолированный тест OK)
- [x] `bin/rails test` — **2026-05-25:** **479 runs**, 1896 assertions, 0 failures

**Этап 3 (ручной + живое демо)** — владелец, см. § H.3 ниже.

### 2.1 Code review перед демо

- [x] ⭐ Code review В1 + правки по находкам (**2026-05-25:** `docs/operations/milestones/veha_1/CODE_REVIEW.md`; исправлен N+1 в `Shop::OrderCreator`; shop+block_g **51/0**)
- [x] Коммит + деплой Fly — **2026-05-25:** 16 коммитов на `develop`; fix npm v1.53 (`4a25187`); CI `Deploy to Fly.io`

### H.0 После деплоя на Fly (demo-стенд develop) — **обязательно до живого демо**

Пока идёт приёмка H.3: в `fly.toml` включены `release_command` (`db:prepare` + `demo:seed`) и `SHOP_BASE_DOMAIN`. Подробно: [`../../FLY_DEMO_STAND.md`](../../FLY_DEMO_STAND.md).

- [ ] ⭐ Деплой `develop` прошёл (GitHub Actions → Fly)
- [ ] ⭐ В логах release: `demo:seed` без ошибки (или ручной `fly ssh console` → `bin/rails demo:seed`)
- [ ] ⭐ Smoke: https://demo-point-a.coffeeos.fly.dev/shop — меню не пустое
- [ ] ⭐ Логин `barista-a@demo.coffeeos.local` / `demo123456` → `/barista`
- [ ] Wildcard `*.coffeeos.fly.dev` в `fly certs` (если поддомены не открываются — см. FLY_DEMO_STAND)
- [ ] После закрытия H.3: **убрать** `demo:seed` из `release_command` (отметить здесь дату)

### 3. Живое демо

Показ **не QA-исполнителю**: заказчик / бариста / менеджер. Инструкция простым языком: [`LIVE_DEMO_SCENARIOS_PLAIN.md`](LIVE_DEMO_SCENARIOS_PLAIN.md); техническая — [`LIVE_DEMO_SCENARIOS.md`](LIVE_DEMO_SCENARIOS.md). Минимум для приёмки — 4 истории в конце plain-дока (§ 10).

**Порядок:** сначала **живое** (H.3) → потом **MCP** по полному списку (~55 сценариев), если нужна регрессия. MCP **не** заменяет живое и **не** гонять до него (кроме срочного релиза без даты демо).

- [ ] ⭐ Демо: бариста → заказ → склад; shop → заказ; УК → точка/каталог (см. LIVE_DEMO § 10)
- [ ] MCP DevTools: прогон `LIVE_DEMO_SCENARIOS.md` — **после** `[x]` живого демо; журнал в `PRACTICES.md` § H.3

---

## I. Закрытие вехи (operations)

- [ ] [`PRACTICES.md`](PRACTICES.md) — Service Objects: код приведён, тесты, известные хвосты
- [ ] `docs/operations/SESSION_STATE.md` — статус «Веха 1 закрыта» или явный список хвостов
- [ ] `docs/operations/CHANGELOG.md` — запись о закрытии В1
- [ ] Список техдолга В1→В3 только здесь или в `MILESTONE_PRACTICES`, **не** в `development_roadmap` / Vision / Architecture

---

## J. Сознательно НЕ делаем в В1

- [ ] — Offline / Drift / Hive / синхронизация
- [ ] — Outbox, Circuit Breaker
- [ ] — Event Sourcing склада (полный журнал как SoT)
- [ ] — Domain Folders (`app/models/sales` и т.д.)
- [ ] — Новые RLS-политики на онбординге
- [ ] — Flutter, киоск
- [ ] — Loyalty, pickup, production, supply как пользовательский продукт в демо

---

## Критерий «Веха 1 закрыта»

Считаем веху закрытой, когда:

1. Все пункты со ⭐ отмечены `[x]` (или явно перенесены в хвост с датой в §I).
2. В §G записан выбранный вариант A или B и код ему соответствует.
3. §I заполнен в operations-доках.
4. Демо одной кофейни проходит без блокеров: shop заказ, barista заказ, базовый склад, роли не пускают куда не надо.

**Дата закрытия:** ____________  
**Кто принял:** ____________  
**Хвосты в В2:** ____________
