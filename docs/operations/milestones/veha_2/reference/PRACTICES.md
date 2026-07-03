# Веха 2 — практики и журнал (операционный)

Папка: `docs/operations/milestones/veha_2/`. Карта: [`README.md`](README.md).

Живой документ: решения, приоритеты, прогон тестов, «где остановились».  
Продуктовый scope — `docs/product/development_roadmap.md` § ВЕХА 2 (без дублирования блоков A–I в roadmap).

**Чеклист:** [`CHECKLIST.md`](CHECKLIST.md). **Онбординг детально:** [`ONBOARDING_CHECKLIST.md`](ONBOARDING_CHECKLIST.md).

**Product docs sync (2026-05-30):** `docs/product/*` + `qa_scenarios.md` — блок «В2 реализовано»; агенты читают **`development_roadmap.md`** первым по scope.

### Code review V2 — **2026-05-30**

- **Вердикт:** к **прогону 10**; правки: OrderCreator N+1, Tbank idempotency claim, callback job lookup, Rack::Attack kiosk path.
- **Тесты:** 554/0 (WSL). **Прогон 10:** частичный PASS — [`QA_ACCEPTANCE_RUN.md`](QA_ACCEPTANCE_RUN.md).
- **Док:** [`CODE_REVIEW.md`](CODE_REVIEW.md)

### Прогон 10 — **2026-05-30**

- **Стенд:** `coffeeos.fly.dev`, deploy после `e97397b`.
- **PASS:** suite 554/0; URL витрины A/B; curl stress 6× cash; card mock `payment_url`; barista/manager заказы.
- **PARTIAL / SKIP:** 3×3 на всех org; kiosk без `DEVICE_TOKEN`; RBAC не полная матрица.
- **Следующее:** добивка **прогона 10** (блоки 1–14) — [`QA_ACCEPTANCE_RUN.md`](QA_ACCEPTANCE_RUN.md); прогона 11 **нет**.

### Прогон 10 — продолжение (2026-06-01)

- **Точка входа агента:** [`../../session/SESSION_STATE.md`](../../session/SESSION_STATE.md).
- **План работ:** [`QA_ACCEPTANCE_RUN.md`](QA_ACCEPTANCE_RUN.md) — таблица блоков 0–14; блок **0** ✅.
- **Не в scope:** Flutter, живое демо, живая оплата, 9 MCP-витрин (делаем 5).
- **Блок 5 (gate):** полный suite WSL — **559/0** *(2026-06-02)*; статусы CR синхронизированы в `CODE_REVIEW.md`.

### Gate (как в В1)

1. Смена/каналы заказа — [`ORDER_ENTRY_AUDIT.md`](ORDER_ENTRY_AUDIT.md).
2. Таск-трекер Done не раньше `[x]` в чеклисте.
3. Правила кода: `.cursor/rules/project/coffeeos-core.mdc`, `coffeeos-performance.mdc`, `coffeeos-services.mdc`, `docs/agents/AGENTS.md`.

---

## Приоритеты (зафиксировано 2026-05-25)

| # | Направление | Зачем |
|---|-------------|--------|
| 1 | Онбординг «коробка» | Клиент заводит org/точки и получает **готовые входы** + изоляцию БД |
| 2 | Связность админок | УК, manager, barista, prep_kitchen на **одних** tenant/каталоге |
| 3 | Оплата | Витрина + QR на столах **уже полезны** без полного киоска |
| 4 | Киоск | Отдельный канал на точку, **та же оплата**, что витрина |
| 5 | Полировка | [`DEMO_FEEDBACK.md`](DEMO_FEEDBACK.md) параллельно, не в В1 |
| 6 | Offline, единая смена, Outbox | Хвост В2 / граница с В3 |

**Архитектура URL (не менять без явного решения):**

- **Клиент** (витрина, киоск): поддомен `{slug}.{SHOP_BASE_DOMAIN}`.
- **Персонал** (barista, manager, prep_kitchen, УК): **общий хост** + `tenant_id` в сессии + RLS — см. [`ONBOARDING.md`](ONBOARDING.md).

---

## Наследие В1 (не ломать без продукта)

| Тема | В1 | В2 |
|------|----|----|
| Shop без смены | Да | Пока да; ужесточение — § F чеклиста |
| `SHOP_SIMULATE_PAYMENT=1` default | Да | Продакшен-стенд: `0` + шлюз |
| Киоск | Флаг `FeatureFlag` | Рабочий UI + устройства |
| Склад v0.1 | Прямой UPDATE без движения | Техдолг → **В3** |
| Новые RLS на онбординге | STOP В1 | Не добавлять; использовать существующие политики |

Техдолг В1 полный список — [`../veha_1/reference/PRACTICES.md`](../veha_1/reference/PRACTICES.md) (не копировать сюда целиком).

---

## Техдолг В2 (вести здесь)

| ID | Тема | Статус | Куда дальше |
|----|------|--------|-------------|
| V2-T1 | Нет карточки «все входы» в УК | **done** §4 ONBOARDING 2026-05-26 | — |
| V2-T2 | `address` не в форме tenant | **done** §2 ONBOARDING 2026-05-26 | — |
| V2-T3 | Staff только manager + franchise из УК | **done** §5 ONBOARDING 2026-05-26 (путь open_as_manager → staff) | wizard — хвост |
| V2-T4 | Киоск без routes | **auth done** | `POST /kiosk/api/auth`; Flutter UI — open |
| V2-T5 | Реальный шлюз не подключён | **done** Т-Банк 2026-05-28 (тест-терминал); прод — после Outbox+CB | PAYMENT |
| V2-T6 | Боевой терминал Т-Банка не включён | **done** *(2026-05-28)* | `1719235292309` на Fly, prod smoke PASS |
| V2-T7 | QR режим B (без домена) | open | Режим A — когда будет домен; §I хвост |
| V2-T8 | Flaky тест `events_controller_test.rb:208` (timing) | **done** *(2026-05-30)* | 200 с + `travel_to`; 23/0, ×5 PASS |
| V2-CR-01 | `catalog_bootstrap.rb` N+1 PTS | **done** *(2026-06-01, блок 1)* | prefetch PTS + bulk create |
| V2-CR-02 | `events_controller` без callback secrets | **in_progress** *(блок 4, 2026-06-02)* | Проверять в Fly именно `CALLBACK_SHARED_SECRET` и `CALLBACK_SHARED_TOKEN` (Dashboard/CLI) |
| V2-CR-03 | `browser_shop_session?` без CSRF verify | **done** *(2026-06-01, блок 2)* | `valid_authenticity_token?` + referer |
| V2-CR-04 | `CacheCounter` MemoryStore | **accepted / wontfix** *(2026-06-02, блок 3)* | Fly **1 pod** — in-process OK; при **2+ серверах** или смене хостинга → **Redis** (или Solid Cache) для общего счётчика |
| V2-CR-05 | Kiosk `KioskSetting` без tenant GUC | **done** *(2026-06-02, блок 3)* | `SET LOCAL` в `kiosk/api/auth` |
| V2-SEC-07 | `shop.html.erb` meta `shop-api-key` | **deferred → В3** *(2026-06-02)* | Задача **V3-SEC-07** — [`veha_3/CHECKLIST.md`](../veha_3/CHECKLIST.md) § E. В2 блок 4: wontfix для demo Fly |
| V2-SEC-08 | **bundler-audit: CVE в гемах (prod)** | **open — обязательно** *(2026-07-03)* | Отдельный шаг до следующего deploy: см. § V2-SEC-08 ниже |
| V2-P10-01 | Прогон 10: 3 org × 3 точки | **done** *(2026-06-01)* | [`PROG10_TENANTS.md`](PROG10_TENANTS.md) |
| V2-P10-02 | Прогон 10: kiosk curl | **done** *(2026-06-01)* | `bin/prog10_fly_smoke.rb` + Prog10 Kiosk MCP |
| V2-P10-03 | Прогон 10: RBAC AUTH-01…09 | **done** *(2026-06-01)* | MCP + регрессия прогон 5 |
| V2-P10-04 | Shop checkout MCP: fixed bottom nav | **done** *(2026-06-01)* | scrollIntoView + клик «Наличные» PASS |
| V2-P10-05 | Staff/RBAC изоляция 9 точек | **done** *(2026-06-02, блок 7)* | `prog10/staff-rbac/prog10_staff_isolation.json`: own `200`, foreign `404` |
| V2-P10-06 | ENT карточка УК (02/07/08) | **done** *(2026-06-02, блок 8)* | `prog10/platform-ent/prog10_ent_card_mcp.json` на demo-a |
| V2-P10-07 | Kiosk→barista: mock card ×9 | **done** *(2026-06-02)* | `prog10/kiosk/prog10_kiosk_barista_card.json` |
| V2-P10-09 | Витрина MCP 5 точек + SHP-09 | **done** *(2026-06-02, блок 10)* | cash+card+SHP-03: `prog10_shop_vitrina_*`, `prog10_shop_vitrina_card_*`, `prog10_shop_shp03*` |
| V2-P10-08 | **Заказ киоска помечается `source=mobile`, не `kiosk`** | **open — после блоков 1–14** | `Shop::OrderCreator` + передача device token в shop API; UI бариста «Киоск» vs «Витрина» |
| V2-BACKLOG-PREP-MULTI | Один заготовочный цех на **несколько** точек продаж | **backlog — после В2** | Сейчас **1 `production_kitchen` = 1 tenant**, RLS верный; CON-06 — изоляция на этой модели. Потом: связь цех↔точки, права не только `Current.tenant_id` |
| V2-P10-11 | Блок 11 CON-02…06 | **done** *(2026-06-02)* | `prog10/_index/prog10_connectivity.json`, тесты + Fly CON-02 |
| V2-P10-12 | Блок 12 Barista↔цех e2e | **done** *(2026-06-02)* | `prog10/warehouse/prog10_warehouse_block12.json`; auto-link sales→prep в backlog V2-BACKLOG-PREP-MULTI |
| V2-P10-13 | Блок 13 финал прогона 10 | **done** *(2026-06-02)* | `prog10/_index/prog10_final_block13.json`, `prog10/_index/prog10_final_index.json` |
| V2-P10-14 | Блок 14 Postmortem | **done** *(2026-06-02)* | `POSTMORTEM_2026-05-28.md` § Прогон 10 |

**Когда править V2-P10-08:** после закрытия QA-блоков 10–14 и §E; отдельный кодовый PR (не смешивать с витриной/RBAC). Иначе отчёты и табло врут про канал заказа.

### V2-SEC-08 — bundler-audit CVE (обязательный техдолг)

**Зафиксировано:** 2026-07-03 · после коммита `b7481dc` (закрыты только `rack`, `rack-session`, `view_component`).

**Почему обязательно:** `bin/bundler-audit check` всё ещё падает — уязвимости в **production**-стеке (Fly), не только dev. Откладывать нельзя: следующий осознанный deploy должен включать патчи.

**Приоритет обновления (prod-hot):**

| Гем / группа | Сейчас (ориентир) | Цель | Риск если не сделать |
|--------------|-------------------|------|----------------------|
| **rails** (actionpack, actionview, activestorage, activesupport) | 8.1.2 | **≥ 8.1.2.1** | XSS, bypass загрузок, DoS в Active Storage |
| **puma** | 7.2.0 | **≥ 7.2.1** | DoS через PROXY protocol (память) |
| **nokogiri** | 1.19.1 | **≥ 1.19.4** | ReDoS, use-after-free при разборе HTML/XML |
| addressable, bcrypt, crass, erb, loofah | ниже advisory | по `bundler-audit` | ReDoS / парсинг — второй проход |

**Порядок шага (отдельно от фич B1.x):**

1. `bundle update rails puma nokogiri` (+ транзитивные по lock).
2. `bin/bundler-audit check` — убедиться, что prod-группа чиста или остаток задокументирован.
3. Регрессия: минимум `bin/rails test` или зоны shop + platform + payment + callbacks.
4. **Deploy на Fly** — только с явным `go` владельца.

**Не делать:** массовый `bundle update` в одном коммите с фичами заказчика; RuboCop mass-fix.

---

## 7 практик (из обсуждения Dodo) — статус В2

| Практика | Веха | Статус | Что делать |
|----------|------|--------|------------|
| **Service Objects** | В1 ✅ / В2 ✅ | Работает | `TbankAdapter`, `OrderCreator`, `PaymentStatusUpdater` — по паттерну. Продолжать в D (Киоск) |
| **Domain Folders** | В4+ | ⏸ Отложено | Не вводить `app/models/{domain}` — пока моделей < 50, AR между «доменами» разрешён |
| **Outbox (Solid Queue)** | В2 (перед прод) | ✅ Done | `Payments::TbankCallbackJob`, retry x5, Solid Queue worker на Fly *(2026-05-28)* |
| **Circuit Breaker** | В2 (перед прод) | ✅ Done | `TbankAdapter#post_json_with_circuit_breaker` *(2026-05-28)* |
| **Event Sourcing склада** | В3 | ❌ Не начато | Склад v0.1 — прямой UPDATE. В3: `StockMovement` как журнал, nightly reconciliation |
| **Read Replicas** | После трафика | ❌ Не начато | Когда появится реальная нагрузка на SELECT-запросы. Fly Postgres replica + `ApplicationRecord.connected_to(role: :reading)` |
| **Blameless Postmortems** | В2 прогон 10 | ✅ § Прогон 10 | [`POSTMORTEM_2026-05-28.md`](POSTMORTEM_2026-05-28.md); §I веха — после §E |

### Порядок «перед боевыми деньгами»

1. ✅ Тест-терминал Т-Банк работает (`1719235292292DEMO`)
2. ✅ Регистрация киоска в manager/devices
3. ✅ **Outbox** — `Payments::TbankCallbackJob` на Solid Queue *(2026-05-28, commit `0338a3e`)*
4. ✅ **Circuit Breaker** — `TbankAdapter#post_json_with_circuit_breaker` *(2026-05-28)*
5. ✅ **Idempotency `/callbacks/tbank`** — Redis `tbank:callback:{PaymentId}:{Status}` *(2026-05-28)*
6. ✅ **Мониторинг** — `StuckPaymentsCheckJob` → Telegram *(2026-05-28)*
7. ❌ §I QA приёмка + Code Review — **ждёт апрува заказчика**
8. ✅ Переключить на боевой терминал (`1719235292309`) — *(2026-05-28, prod smoke PASS)*

---

## Service Objects (продолжение В1)

Новая оркестрация В2 — в `app/services/{namespace}/`:

- Онбординг: расширять `Platform::TenantOnboarding::*`, не раздувать `TenantsController`.
- Оплата: провайдер-адаптер + существующий `Callbacks::PaymentStatusUpdater`.
- Киоск: по аналогии с `Shop::OrderCreator` (или общий базовый сервис — **только** если явно согласовано).

---

## Известные пропуски (фиксировать здесь)

| Пропуск | AUTH-ID | Обнаружен | Статус |
|---------|---------|-----------|--------|
| `shift_manager` (`shift-a@demo.coffeeos.local`) → `/manager` | AUTH-06 | 2026-05-28 | ✅ Закрыт прогон 5 |
| `franchise_manager` (`franchise@demo.coffeeos.local`) → `/manager` | AUTH-02 | 2026-05-28 | ✅ Закрыт прогон 5 |
| `prep_kitchen_worker` (`pk-worker@demo.coffeeos.local`) → `/prep_kitchen` | AUTH-08 | 2026-05-28 | ✅ Закрыт прогон 5 |

**Правило:** AUTH-блок прогонять полностью (AUTH-01…AUTH-10), не выборочно.

---

## Журнал изменений (дописывать снизу)

- **2026-06-04 — franchise staff RBAC + sync DEMO_FEEDBACK — ЗАКРЫТ (MCP Fly)**
  - **Задача:** у `franchise_manager` скрыть «Персонал»; у GM/УК оставить.
  - **Код:** `Manager::BaseController#staff_management_visible?`, sidebar, `StaffController` guard.
  - **Коммиты:** `7311338`, `62ced8e`; MCP — [`mcp_franchise_staff_fly_2026-06-04.json`](artifacts/demo-feedback/mcp_franchise_staff_fly_2026-06-04.json).

- **2026-06-04 — §2.3 оплата витрина: корзина до успешной оплаты — ЗАКРЫТ (MCP Fly)**
  - **Проблема (заказчик):** после «Оплатить» и ухода на Т-Банк свайп назад → «Корзина пуста», заказ не в истории.
  - **Fix:** `OrderCreator` не чистит `shop_cart` при `pending_payment`; `PendingOrderSession` + reuse; `PaymentReturnsController`; `PaymentResult.svelte`; `abandon`/`finalize`; кнопка «Идёт оплата…».
  - **Коммиты:** `11ab05f`, `06115fb` (ops).
  - **Deploy:** Fly `deployment-01KT8Q97MRQS1S4T060MR3Y3ZQ`.
  - **MCP Fly:** ФИО/лоадер/корзина после банка — **PASS** (`mcp_section_2_3_fly_2026-06-04.json`).
  - **Не в scope MCP:** успех оплаты + история; подсчёт дублей в БД.
  - **Следующий (на момент записи):** §2.5, онбординг, franchise staff — **закрыто 2026-06-04** (см. журнал ниже).

- **2026-06-04 — §2.4 двойной «Оплатить» — ЗАКРЫТ (MCP Fly)**
  - **MCP:** 2 клика на оформлении → «Идёт оплата…», 2-й blocked, один `pay.tbank.ru` — **PASS** (`mcp_section_2_4_fly_2026-06-04.json`).
  - **Код:** тот же `11ab05f` (`PendingOrderSession`, reuse).
  - **Честно:** количество заказов в БД на Fly не пересчитывали.

- **2026-05-30 — V2-T8 flaky callback test — ЗАКРЫТ**
  - **Проблема:** `events_controller_test.rb:208` — timestamp 299 с назад, race на границе `CALLBACK_MAX_AGE_SECONDS=300`.
  - **Fix:** `travel_to` + timestamp **200 с** назад; `TimeHelpers` в тест-классе.
  - **Прогон:** файл 23 runs, 39 assertions, 0 failures; целевой тест ×5 PASS.
  - **Ops:** `CHECKLIST.md` §H, `POSTMORTEM_2026-05-28.md`, `CHANGELOG` v1.69.

- **2026-05-26 — ONBOARDING §7 Инфра (URL / DNS / slug)**
  - **Код:** валидация reserved slug на `Tenant`; подсказка в форме точки; UrlBuilder fallback для legacy reserved.
  - **Проверка:** Fly — без `SHOP_BASE_DOMAIN`; режим A — subdomain на карточке; shop API по Host; slug `admin` отклоняется.
  - **Док:** `INFRA_URLS.md` § ONBOARDING §7 статус стендов.
  - **Тесты:** `onboarding_infra_test.rb` 5/18; `tenant_slug_validation_test.rb` 2/4; `url_builder_test` +1.
  - **Чеклист:** §7 `[x]`. **ONBOARDING блок A–7 закрыт.**

- **2026-05-26 — ONBOARDING §6 Связность (smoke)**
  - **Проверка:** УК меняет `base_price` в `/admin/menu` → PTS + витрина `/shop/api/products/:id`; barista заказ → GM видит в `manager/shifts/:id` и `/manager/orders`; prep_kitchen confirm только своего tenant.
  - **Код:** изменений не потребовалось (В1: PublishProductService, barista orders, prep_kitchen RLS).
  - **Тесты:** `onboarding_connectivity_test.rb` — 3 runs, 31 assertions, 0 failures.
  - **Чеклист:** §6 `[x]`. **Следующий:** §7 Инфра.

- **2026-05-26 — ONBOARDING §5 Staff (боевые входы)**
  - **Код:** `open_as_manager` с `to=staff` → redirect на manager/staff; кнопка «Создать staff →» на карточке точки.
  - **Проверка:** barista и GM создаются через manager/staff после open_as_manager; login → `/barista` / `/manager`; сброс пароля (пустое поле = без изменений); open_as_manager на 3 sales_point.
  - **Док:** `STAFF_ACCESS.md` — пароль, сброс, путь УК.
  - **Тесты:** `onboarding_staff_test.rb` — 5 runs, 65 assertions, 0 failures.
  - **Чеклист:** §5 `[x]`. **V2-T3** closed (wizard — хвост). **Следующий:** §6 Связность.

- **2026-05-26 — ONBOARDING §4 Карточка «все входы»**
  - **Код:** `Platform::TenantOnboarding::EntryPoints`; `TenantsController#show`; partial `_entry_points_card` на show/edit; redirect после create/update → карточка; ссылка «Карточка» в index/dashboard.
  - **Проверка:** org/slug/address/city; URL витрины (режим A/B); панели `/login`, `/manager`, `/barista`, `/prep_kitchen`; модули on/off; чеклист staff (✓/создайте); киоск — URL или «выкл»; копирование витрины.
  - **Тесты:** `entry_points_test.rb` — 4 runs, 23 assertions; `onboarding_entry_points_test.rb` — 3 runs, 43 assertions; обновлён §2 sales_point redirect.
  - **Чеклист:** §4 `[x]`. **V2-T1** closed. **Следующий:** §5 Staff.

- **2026-05-26 — ONBOARDING §3 Заготовочный цех (полный цикл)**
  - **Проверка:** УК создаёт `production_kitchen` + модуль `prep_kitchen` (barista/menu/kiosk off); staff `prep_kitchen_manager` через manager/staff после `open_as_manager`; login → `/prep_kitchen`.
  - **Код:** изменений не потребовалось (В1: форма type, модули, staff, prep_kitchen panel).
  - **Тесты:** `test/integration/platform/onboarding_prep_kitchen_test.rb` — 2 runs, 30 assertions, 0 failures.
  - **Чеклист:** §3 `[x]`. **Следующий:** §4 карточка «все входы».

- **2026-05-26 — ONBOARDING §2 Точка продаж (полный цикл)**
  - **Код:** поле `address` в форме `/admin/tenants` + `tenant_params`.
  - **Проверка:** создание 3 точек (org, slug, city, address, sales_point); модули menu+barista, kiosk off; flash URL при `SHOP_BASE_DOMAIN`; PTS + shop API не пустой; RLS orders A≠B.
  - **Rollback:** уже был — `test/controllers/platform/tenants_controller_test.rb`.
  - **Тесты:** `test/integration/platform/onboarding_sales_point_test.rb` — 5 runs, 61 assertions, 0 failures.
  - **Чеклист:** `ONBOARDING_CHECKLIST.md` §2 — `[x]`.
  - **Следующий шаг:** §3 Заготовочный цех.

- **2026-05-26 — ONBOARDING §1 Организация (полный цикл)**
  - **Проверка:** `/admin/organizations/new` (namespace `platform`, path `admin`) — форма name + slug; create → org в списке; ссылка «Точка» с `organization_id` → tenant привязан к org.
  - **Код:** изменений не потребовалось (уже в В1: `Platform::OrganizationsController`, index с `new_platform_tenant_path(organization_id:)`).
  - **Тесты:** `test/integration/platform/onboarding_organization_test.rb` — 3 runs, 27 assertions, 0 failures.
  - **Чеклист:** `ONBOARDING_CHECKLIST.md` §1 — `[x]`.
  - **Следующий шаг:** §2 Точка продаж (×3).

- **2026-05-30 — Kiosk auth API + docs (без закрытия §I)**
  - **Код:** `POST /kiosk/api/auth` (`c44b1eb`); тесты 6/0
  - **Docs:** [`FLUTTER_API.md`](FLUTTER_API.md), черновик postmortem
  - **Prod:** worker `DB_POOL=8`, callback via worker PASS (`85bef120`)
  - **§I / CODE_REVIEW:** не закрыты — нужен апрув заказчика

- **2026-05-28 — Prod E2E callback + barista PASS**
  - **Заказ:** `f8427fc4-…`, PaymentId `8576370191`, 179₽
  - **Callback:** CONFIRMED → `accepted`, payment `succeeded` (`perform_now` fallback)
  - **Barista:** `##202605-0008` на табло ACCEPTED; accept после fix broadcast
  - **Тест-карта prod:** `ACTIVATION_ERROR` (ожидаемо)
  - **Fixes:** idempotency MemoryStore, solid schema load, barista broadcast rescue
  - **Tests:** 544/0

- **2026-05-28 — Prod terminal включён + smoke PASS**
  - **Fly:** `TBANK_TERMINAL_KEY=1719235292309`, `SHOP_SIMULATE_PAYMENT=0`, rolling deploy OK
  - **Smoke (DevTools MCP):** card Init → `https://pay.tbank.ru/EJe3CaXH`, 179₽ на форме; cash → `accepted`
  - **Тесты:** 47 payment-related runs, 0 failures
  - **Не прогоняли:** полная оплата картой (реальные деньги) и callback E2E
  - **V2-T6:** closed

- **2026-05-28 — Fix card/sbp 500 + smoke PASS**
  - **Причина:** Circuit breaker на SolidCache → `RangeError` / broken increment
  - **Fix:** `Payments::CacheCounter` → MemoryStore; `void_pending_online_order!`; `rescue_from OrderCreator::Error`
  - **Коммиты:** `80e38be`, `884cdea`
  - **Smoke:** card 200 → `pay.tbank.ru`, 179₽; cash 200; suite 544 runs
  - **Статус:** готовы к боевому терминалу (апрув заказчика)

- **2026-05-28 — Pre-prod smoke (Chrome DevTools MCP) — частичный PASS**
  - **Suite:** 541 runs, 0 failures
  - **Shop A/B:** каталог OK (`2fdee1ac-…`, `655aaccb-…` из `DEMO_LOGINS.md`)
  - **Cash order:** ✅ `accepted` 179₽
  - **Card order:** ❌ HTTP 500 на Init Т-Банка (circuit/T-Bank) — **блокер боевого терминала**
  - **Manager:** ✅ `shift-a@…` → `/manager`
  - **Доки:** `PAYMENT.md` § Smoke, `QA_ACCEPTANCE_RUN.md` прогон 0, `ISSUES.md`
  - **Ждём апрув** на fix card/sbp перед prod terminal

- **2026-05-28 — §H Надёжность — РЕАЛИЗОВАН + push + deploy**
  - **Коммит:** `0338a3e` — Outbox, CB, Idempotency, Monitoring
  - **Idempotency:** `Callbacks::TbankController` — Redis `tbank:callback:{PaymentId}:{Status}` TTL 24ч
  - **Circuit Breaker:** `Payments::TbankAdapter` — 5 ошибок → circuit open 60с
  - **Outbox:** контроллер enqueue → `Payments::TbankCallbackJob` (retry x5)
  - **Мониторинг:** `Payments::StuckPaymentsCheckJob` — pending > 30 мин → `TelegramAlertJob`
  - **Тесты:** **541 runs, 0 failures, 0 errors**
  - **Deploy:** `coffeeos.fly.dev` — ✅ `2026-05-28`, release_command OK, smoke checks passed
  - **Не включено:** боевой терминал Т-Банка (остаётся DEMO), refund — В3

- **2026-05-28 — §H Надёжность — уточнён и расширен**
  - Добавлены: Idempotency `/callbacks/tbank` (защита от двойного webhook), мониторинг зависших `pending_payment` > 30 мин.
  - Refund вынесен в В3.
  - Порядок перед боевыми деньгами обновлён (8 шагов).

- **2026-05-28 — §D Киоск — частично закрыт**
  - Регистрация устройства `device_type: kiosk` в manager/devices — готово.
  - `ORDER_ENTRY_AUDIT.md` — киоск зафиксирован.
  - Остальные 4 пункта — ждут Flutter-приложения (срок неизвестен).
  - `KIOSK.md` обновлён: что готово, API контракт черновик, инструкция симуляции.

- **2026-05-30 — §F, §G, §D — решения для закрытия В2**
  - **§F:** смена barista/manager — да; shop/киоск — нет. Код «смена на всех каналах» + Z-отчёт → **В3**.
  - **§G:** offline-first целиком → **В3**.
  - **§D В2:** витрина + curl smoke ✅; Flutter UI → **В3**.
  - **§E:** DEMO_FEEDBACK **открыт** — блокер §I до фидбека заказчика.

- **2026-05-28 — §F, §G — решение (устарело, см. 2026-05-30)**
  - §F (кассовая дисциплина): привязка витрины к смене — не делаем пока нет продуктового решения.
  - §G (Offline-first): откладываем в В3 или до первого клиента с проблемами связи.

- **2026-05-30 — Прогон 6 prod smoke (checklist)**
  - **SHOP_API_KEY:** задан на prod (401 без ключа, products 200 с ключом из meta `/shop`).
  - **AUTH-06:** `shift-a@demo.coffeeos.local` → `/manager` PASS.
  - **Kiosk:** curl auth PASS; cart+order curl PARTIAL (session cookie — fix `CartService#touch_cart_session!`); E2E barista PASS (cash «Smoke QA6b», `##202605-0015`).
  - **Новая org:** `smoke-org-qa6-0530` + tenant `d8e287c5-5524-423c-8e5a-605570c69517`, shop API products 200.
  - **Журнал:** `QA_ACCEPTANCE_RUN.md` прогон 6. §I не закрыта.

- **2026-05-30 — Прогон 7 prod curl smoke (kiоск API)**
  - **Deploy:** `e932944` → `11f40b6` (`skip_forgery_protection` в `Shop::Api::BaseController`; `null_session` ломал cookie jar для curl/Flutter).
  - **Curl:** GET `/shop` → cookie → cart/add → cart GET → orders cash — **PASS** (`Kiosk Curl Prog7`, order `e3a06dc9-…`, 179₽ accepted).
  - **Barista:** `##202605-0016` в ACCEPTED без F5.
  - **Тест:** `test/integration/shop/api/cart_persistence_test.rb`.
  - **Локально:** PASS через WSL — `1 run, 5 assertions, 0 failures` (2026-05-30).
  - **Журнал:** `QA_ACCEPTANCE_RUN.md` прогон 7. §I не закрыта.

- **2026-05-30 — §H UX таймаут БД >5 с (qa 6.2) — PASS**
  - **Код:** `slow_request_controller.js` + fetch tracker; overlay skeleton в layout (barista/manager/УК/auth/prep_kitchen) и shop Svelte `SlowRequestOverlay`.
  - **Dev/test:** `GET /test/slow_page`, `GET /test/slow_json` (`Rails.env.local?` only).
  - **Тест:** `test/integration/slow_request_ux_test.rb` — 2 runs, 9 assertions, 0 failures (WSL).
  - **MCP (8b):** login/shop/barista overlay PASS на `localhost:3001`; full suite **554/0** (WSL).
  - **Fix (8c):** `/test/slow_page` — instant HTML + auto-fetch slow_json; MCP overlay PASS.
  - **Deploy (9):** push `7b72132` → Fly; prod curl kiosk PASS + MCP shop/barista *(2026-05-30)*.
  - **Журнал:** `QA_ACCEPTANCE_RUN.md` прогон 8–9.

- **2026-05-28 — §C Реальная оплата (Т-Банк) — ЗАКРЫТ**
  - **Код:** `Payments::TbankAdapter` (Init API, Token, маппинг статусов); `Shop::OrderCreator` → адаптер → `payment_url`; `Callbacks::TbankController` + `POST /callbacks/tbank`; `PaymentStatusUpdater` + `OrderRecipeDeduction`; `Checkout.svelte` — radio card/sbp/cash + редирект.
  - **Секреты:** `fly secrets set TBANK_TERMINAL_KEY TBANK_PASSWORD TBANK_RETURN_URL SHOP_SIMULATE_PAYMENT=0`.
  - **Проверка:** browser-тест → редирект `https://pay.tbank.ru/x77ZGOty`, 179₽; Manager CloseWizard → блок «Онлайн-платежи (витрина, за 24ч)» — 1 pending платёж виден.
  - **Тесты:** TbankAdapter x11 + TbankController x8; полный suite **539 runs, 0 failures** (1 pre-existing flaky timing).
  - **Коммиты:** `7593cde` → `a8eade0` → `7b8a0e3`.
  - **Техдолг:** V2-T5 closed; V2-T6 open (боевой терминал — после Outbox+CB).

- **2026-05-25** — Создан комплект доков В2; приоритет: коробка → оплата → киоск; фидбек в `DEMO_FEEDBACK.md`.
- **2026-05-25** — Базовый suite В1 на `develop`: **479 runs, 0 failures** (эталон до изменений В2).

---

## Веха 3

_(Event Sourcing склада, nightly reconciliation, анти-фрод — при старте В3)_
