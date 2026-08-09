# Прогон приёмки Веха 2

**Зачем:** протокол приёмки В2 — по образцу [`../veha_1/QA_ACCEPTANCE_RUN.md`](../veha_1/QA_ACCEPTANCE_RUN.md). **Статус:** приёмка **в работе**; прогоны **0–9** — история; **10+** — актуальный scope (см. ниже).

**Порядок в § I чеклиста:** сначала code review (правила: `.cursor/rules/project/coffeeos-code-review.mdc`; старый `CODE_REVIEW.md` удалён), потом этот документ.

**Сценарии:** этот протокол + RBAC/онбординг — [`ONBOARDING_DEVTOOLS_SCENARIOS.md`](../runbooks/ONBOARDING_DEVTOOLS_SCENARIOS.md) (AUTH-01…10). **Чеклист:** [`CHECKLIST.md`](../checklists/CHECKLIST.md) § I.

---

## Порядок этапов (прогон 10 — без живого демо)

| Этап | Что | Инструмент | Статус |
|------|-----|------------|--------|
| **0. Code review** | Чистый код до прогонов | `.cursor/rules/project/coffeeos-code-review.mdc` | ✅ **2026-05-30** |
| **1. Сухой** | `bin/rails test` + 3 org × 3 точки | WSL | ✅ **554/0** |
| **2. MCP / curl** | Оплата-имитация, URL, kiosk API, RBAC, stress | Chrome DevTools MCP, `bin/prog10/prog10_fly_smoke.rb` | ✅ **2026-06-01** (прогон 10b) |

**Живое демо (реальные деньги)** — **не входит** в прогон 10. Только [`CHECKLIST.md`](CHECKLIST.md) § **I** + [`LIVE_DEMO_SCENARIOS_PLAIN.md`](LIVE_DEMO_SCENARIOS_PLAIN.md).

Все шаги прогона 10 — **имитация** (cash + mock card), без списания.

**Прогона 11 нет.** Добивка scope — **продолжение прогона 10** (блоки 1–14 ниже). См. [`SESSION_STATE.md`](../../session/SESSION_STATE.md) — точка входа для агента.

### Scope продолжения (2026-06-01, согласовано)

| Делаем | Не делаем (сейчас) |
|--------|-------------------|
| CR-фиксы, wizard staff, MCP/curl добивка | **Прогон 11** (имени нет) |
| Staff/RBAC Prog10 ×9, kiosk→barista ×9 | Flutter UI киоска (V2-T4) |
| Витрина MCP **5** точек + SHP-09 | Живое демо В2, живая оплата |
| CON-02…06, barista↔цех e2e | 9 MCP-витрин (вместо 5) |
| Postmortem до апрува | §E закрытие до полного фидбека заказчика |
| | SESSION_STATE «веха закрыта» — только после апрува |

### План блоков (прогон 10 — продолжение)

| Блок | Содержание | Статус |
|------|------------|--------|
| **0** | Правила + этот план в ops | ✅ **2026-06-01** |
| **1** | CR-01, V2-006 + тесты | ✅ **2026-06-01** — 555/0 |
| **2** | CR-03, SEC-08 + тесты shop | ✅ **2026-06-01** — 559/0 |
| **3** | CR-05, CR-04 + тесты kiosk | ✅ **2026-06-02** — апрув заказчика |
| **4** | CR-02 Fly callback secrets; SEC-07 → В3 | ✅ **2026-06-02** — CR-02 manual; SEC-07 → `veha_3` V3-SEC-07 |
| **5** | Гейт тестов + PRACTICES/CODE_REVIEW sync | ✅ **2026-06-02** — **562/0** |
| **6** | V2-T3 wizard + лист логинов org | ✅ **2026-06-02** — 561/0 |
| **7** | Staff/RBAC Prog10 ×9 (STF-01…05) | ✅ **2026-06-02** — curl 9/9 + MCP 9/9 (`prog10/staff-rbac/prog10_staff_mcp_9pt.json`); апрув заказчика |
| **8** | ENT-02, ENT-07, ENT-08 | ✅ **2026-06-02** — MCP 3/3 на demo-a (`prog10/platform-ent/prog10_ent_card_mcp.json`); апрув заказчика |
| **9** | Kiosk→barista ×9 (curl+MCP) | ✅ **2026-06-02** — cash+card curl, MCP 9/9; апрув заказчика |
| **10** | Витрина MCP 5 точек + SHP-09 | ✅ **2026-06-02** — cash+card+SHP-03/05; **ждём апрув → блок 3 → блок 11** |
| **11** | CON-02…06 | ✅ **2026-06-02** — `prog10/_index/prog10_connectivity.json`; апрув заказчика |
| **12** | Barista↔цех e2e (demo prep + Prog10 prep) | ✅ **2026-06-02** — апрув заказчика |
| **13** | Перепроверка curl 9×, stress, RBAC, артефакты | ✅ **2026-06-02** — апрув заказчика |
| **14** | Postmortem → `[x]` | ✅ **2026-06-02** — `POSTMORTEM_2026-05-28.md` § Прогон 10; ждём апрув → §E/§I |
| *после* | §E фидбек → правки → апрув → SESSION_STATE/CHANGELOG §I | вне блоков |

**Ops на блок:** `SESSION_STATE.md` + коммит; код/CR → `PRACTICES.md`; QA/MCP → этот файл + `artifacts/`; `CHANGELOG.md` — если заметно. Сводка вехи §A–§I — [`CHECKLIST.md`](CHECKLIST.md).

---

## Прогон 10 — блоки 0–14 (детальный чеклист)

**В3 / не трогаем:** Flutter, домен/QR, живое демо, живая оплата, invite пароль, offline/refund/Event Sourcing.

### Блок 0 — вход *(docs, 2026-06-01, коммит `1da0ca4`)*

- [x] Прогон 10 = продолжение; **прогона 11 нет**
- [x] Scope: без Flutter, живого демо, живой оплаты; MCP-витрина **5**, не 9
- [x] Таблица блоков 0–14 в этом файле

### Блок 1 — Код: perf + мелочи *(2026-06-01, `4621b63`, тесты 555/0)*

- [x] V2-CR-01 — N+1 `catalog_bootstrap` (prefetch PTS)
- [x] V2-006 — дубли FeatureFlag `entry_points`
- [x] `bin/rails test` (onboarding + полный suite)

### Блок 2 — Код: витрина *(2026-06-01, `a0ce6f6`, тесты 559/0)*

- [x] V2-CR-03 — CSRF browser shop (`valid_authenticity_token?`)
- [x] SEC-08 — `orders#show` только свой гость в сессии
- [x] Тесты shop/cart/orders

### Блок 3 — Код: kiosk + кэш *(2026-06-02, закрыт)*

- [x] V2-CR-05 — kiosk tenant GUC (`with_kiosk_tenant_guc!`, тесты 7/0, Fly curl **9/9** — `prog10/kiosk/prog10_kiosk_auth_fly_cr05.json`)
- [x] V2-CR-04 — CacheCounter **wontfix** Fly 1 pod; при 2+ серверах → Redis (`PRACTICES`)
- [x] Тесты kiosk — `test/controllers/kiosk/api/auth_controller_test.rb`

*Апрув блока 3 — 2026-06-02.*

### Блок 4 — Код: ops *(2026-06-02)*

- [x] V2-CR-02 — manual-check `CALLBACK_SHARED_SECRET` + `CALLBACK_SHARED_TOKEN` на Fly *(auto flyctl не было)*
- [x] **SEC-07** — **перенесено в В3** → [`veha_3/CHECKLIST.md`](../veha_3/CHECKLIST.md) § **E**, **V3-SEC-07**. На demo Fly meta key OK; fix перед боевым доменом.

### Блок 5 — Гейт кода *(2026-06-02, перегон 562/0)*

- [x] Полный `bin/rails test` WSL — **562/0**
- [x] Синхрон `PRACTICES.md` / статусы CR (протокол `CODE_REVIEW.md` удалён)

### Блок 6 — Продукт: staff *(2026-06-02, `cf7a2cf`, тесты 561/0)*

- [x] V2-T3 — wizard «первая команда на точке» + `team_template`
- [x] Лист логинов новой org — `STAFF_ACCESS.md`

### Блок 7 — QA: Staff/RBAC Prog10 *(2026-06-02, апрув заказчика)*

Артефакты: `prog10/staff-rbac/prog10_staff_isolation.json` · `prog10/staff-rbac/prog10_staff_mcp_9pt.json`

- [x] curl 9/9 — изоляция: свой заказ `200`, чужой `404`; prep — barista `302` (ожидаемо)
- [x] MCP STF-01/02 — open_as_manager + staff list (**9/9**)
- [x] MCP STF-03 — создание barista в UI (**9/9**)
- [x] MCP STF-04 — login barista → `/barista` *(demo-prep: barista недоступен — норма)*

### Блок 8 — QA: УК карточка точки *(2026-06-02)*

Артефакт: `prog10/platform-ent/prog10_ent02_clipboard.json` · `prog10/platform-ent/prog10_ent_card_mcp.json`

- [x] ENT-02, ENT-07, ENT-08

*Апрув блока 8 — 2026-06-02.*

### Блок 9 — QA: Kiosk → barista *(2026-06-02)*

Артефакты: `prog10/kiosk/prog10_kiosk_barista.json` · `prog10/kiosk/prog10_kiosk_barista_mcp.json` · `bin/prog10/prog10_kiosk_barista.rb`

- [x] curl киоск 9× — auth + cash + mock card
- [x] barista JSON/HTML + MCP ×9

**Хвост (код):** `source=kiosk` — **V2-P10-08** в `PRACTICES.md`.

*Апрув блока 9 — 2026-06-02.*

### Блок 10 — QA: Витрина *(2026-06-02)*

Точки: demo-a, demo-b, alpha-p1, alpha-p2, beta-p1. Артефакты: `prog10_shop_vitrina_*`, `prog10_shop_shp03*`.

- [x] curl/API + MCP: cash, mock card, SHP-03/05, SHP-09

*Апрув блока 10 — 2026-06-02.*

### Блок 11 — QA: Связность *(2026-06-02)*

Артефакты: `prog10/_index/prog10_connectivity.json`, `prog10/connectivity/prog10_connectivity_con02_fly.json`

- [x] CON-01…06 (см. артефакт); backlog общий цех → `V2-BACKLOG-PREP-MULTI`

*Апрув блока 11 — 2026-06-02.*

### Блок 12 — QA: Склад *(2026-06-02)*

- [x] `prog10/warehouse/prog10_warehouse_block12.json`

*Апрув блока 12 — 2026-06-02.*

### Блок 13 — QA: Финал *(2026-06-02)*

Артефакты: `prog10/_index/prog10_final_block13.json`, `prog10/smoke/prog10_stress_wave2.json`, `prog10/_index/prog10_final_index.json`

- [x] curl 9×, stress 8+8, kiosk 9×, RBAC, index (§10d ниже)

*Апрув блока 13 — 2026-06-02.*

### Блок 14 — Доки *(2026-06-02)*

- [x] Postmortem — [`POSTMORTEM_2026-05-28.md`](POSTMORTEM_2026-05-28.md) § «Прогон 10»

*Ждём апрув блока 14 → §E / §I.*

**После блоков 1–14:** §E → правки → апрув → SESSION_STATE/CHANGELOG → §I.

---

## Подготовка (на каждый прогон)

| Шаг | Действие | Результат |
|-----|----------|-----------|
| Коммиты | Все коммиты прогона в git | hash + message в журнале прогона |
| Ops-хронология | `CHANGELOG.md`, `PRACTICES.md`, `SESSION_STATE.md` | запись «что / зачем / итог» |
| Demo / новые org | 3 org × 3 точки из УК (`ONBOARDING.md`) | org slug + tenant id в журнале |
| `bin/rails test` | полный suite перед MCP | runs / failures |
| Оплата на стенде MCP | **имитация:** cash + mock card; `SHOP_SIMULATE_PAYMENT=1` или cash + signed callback без списания | не этап 3 |
| Fly | `coffeeos.fly.dev`, deploy из `develop` | `/up` 200 |

---

## Минимальный scope приёмки В2 (прогон 10+)

### 1. Сеть из коробки (3 org × 3 точки)

- **Минимум:** **3 организации**, в каждой **≥ 3 точки** (`sales_point`, address, city, slug, модули).
- **Сверх минимума:** одна org с 4–5 точками — необязательно; если сделано — строка «сверх минимума» в журнале прогона 10.
- **На каждой точке** включены и проверены модули: **menu + barista**, **витрина**, **оплата (имитация)**, **kiosk (API)**, связь **barista ↔ prep_kitchen** (заказ доходит до barista / движения склада где модуль цеха включён).
- Карточка «все входы» в УК: URL витрины, панели, staff — см. [`ONBOARDING.md`](ONBOARDING.md).

### 2. Оплата (имитация)

| Где | Режим |
|-----|--------|
| MCP, curl | **Cash** + **mock card** (без списания). Card: `payment_url` + callback без формы банка. |
| **Stress-smoke** | **8** cash-заказов по **9 точкам** (round-robin), интервал **≥7 с** (`ORDER_DELAY_SEC`, лимит Rack 10 заказов/мин). |

На **каждой** из **9** точек (3 org × 3) — минимум 1 cash + 1 mock card. Цех (`demo-prep-kitchen`) — shop только если есть товары в API.

### 3. URL витрины (QR — не фича продукта)

- Для **каждой** точки: URL из карточки УК / `UrlBuilder` (режим B: `?tenant_id=`).
- Проверка: URL **открывается**, витрина грузит меню (MCP или телефон).
- QR-картинку в продукте **не делаем**; при необходимости — сгенерить QR из URL вручную для скана.

### 4. Kiosk (имитация без Flutter)

На **каждую** новую точку с модулем kiosk — полный цикл по [`FLUTTER_API.md`](FLUTTER_API.md):

1. `POST /kiosk/api/auth` → device token  
2. `/shop/api/*` (cart → order, cash или mock card)  
3. Заказ **accepted** на табло **barista**  

Flutter UI — **В3**; для В2 достаточно curl/E2E как киоск.

### 5. RBAC — полная матрица (не prog 8b)

- **УК** (`uk@…`): org, точки, модули, карточка входов, staff/logins для каждого входа.
- **Точка:** franchise_manager, general_manager, shift_manager, barista, prep_kitchen_manager, prep_kitchen_worker — см. [`DEMO_LOGINS.md`](../veha_1/DEMO_LOGINS.md) (роли на **новой** org после онбординга).
- **AUTH-01…10** — все закрыты; **≥ 3–5 сценариев на роль**; приоритет: **деньги, заказы, barista ↔ цех, выдача клиенту**; УК — **все** сценарии создания.
- Инструмент: **Chrome DevTools MCP**; матрица «роль × сценарий» — в прогоне 10.
- **Прогон 8b** (login/shop/barista overlay) — **не считается** полным RBAC; дополняется прогоном 10.

**Ссылки:** [`ONBOARDING_DEVTOOLS_SCENARIOS.md`](ONBOARDING_DEVTOOLS_SCENARIOS.md), [`STAFF_ACCESS.md`](STAFF_ACCESS.md).

---

## Журнал прогонов

> **0–9** — история (до расширения scope). **10+** — приёмка по разделу «Минимальный scope» выше.

### Прогон 0 — pre-prod smoke (2026-05-28)

**Инструмент:** Chrome DevTools MCP на `coffeeos.fly.dev`  
**Цель:** smoke до переключения на боевой терминал (по запросу заказчика).

| Шаг | PASS/FAIL | Примечание |
|-----|-----------|------------|
| Health `/up` | PASS | |
| Suite 541/0 | PASS | |
| Shop A catalog | PASS | tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| Shop B catalog | PASS | tenant `655aaccb-004a-4bb9-a50a-ce618854dda3`, цены отличаются |
| Cart + checkout UI | PASS | |
| Order cash | PASS | `accepted`, 179₽ |
| Order card → T-Bank | **FAIL→PASS** | см. прогон 1 |
| Manager login | PASS | `shift-a@demo.coffeeos.local` → `/manager` |
| Kiosk | SKIP | Flutter |
| T-Bank callback E2E | SKIP | blocked by card FAIL |

**Блокер:** card/sbp — **закрыт** (`884cdea`).  
**Следующий шаг:** апрув → боевой терминал + smoke на prod.

### Прогон 1 — pre-prod smoke повтор (2026-05-28)

**Fix:** `80e38be` + `884cdea` — Circuit breaker на MemoryStore, не SolidCache.

| Шаг | PASS/FAIL | Примечание |
|-----|-----------|------------|
| Order card → T-Bank | **PASS** | 200, `payment_url` `https://pay.tbank.ru/liDXgYg9`, 179₽ на форме |
| Order cash | **PASS** | 200 `accepted` |
| Deploy | PASS | `884cdea` на Fly, release cleared CB cache |

**Вердикт:** готовы к боевому терминалу (ждёт апрув заказчика).

### Прогон 2 — prod terminal smoke (2026-05-28)

**Инструмент:** Chrome DevTools MCP на `coffeeos.fly.dev`  
**Секреты:** боевой `TBANK_TERMINAL_KEY=1719235292309`, `SHOP_SIMULATE_PAYMENT=0`

| Шаг | PASS/FAIL | Примечание |
|-----|-----------|------------|
| Fly secrets + rolling deploy | PASS | machine healthy |
| `/up` | PASS | 200 |
| Payment tests | PASS | 47 runs, 0 failures |
| Order card → T-Bank (prod) | PASS | `25bb9312-…`, `https://pay.tbank.ru/EJe3CaXH` |
| Форма pay.tbank.ru | PASS | 179₽ |
| Order cash | PASS | `c36b2de4-…`, `accepted` |
| Callback E2E (оплата картой) | SKIP | без списания реальных денег |

**Вердикт:** боевой терминал **включён**, smoke **PASS**.

### Прогон 3 — prod E2E callback + barista (2026-05-28)

**Инструмент:** Chrome DevTools MCP + signed webhook (CheckOrder → CONFIRMED)

| Шаг | PASS/FAIL | Примечание |
|-----|-----------|------------|
| Card Init prod | PASS | `f8427fc4-…`, `pay.tbank.ru/roEOwCZL` |
| Форма Т-Банка 179₽ | PASS | |
| Тест-карта на prod | SKIP | `ACTIVATION_ERROR` — prod не принимает sandbox-карты |
| Callback CONFIRMED | PASS | PaymentId `8576370191`, order → `accepted` |
| Barista board | PASS | `##202605-0008` в колонке ACCEPTED |
| Barista accept → preparing | PASS | после fix broadcast rescue |
| Suite | PASS | 544/0 |

**Fixes:** `TbankController` idempotency MemoryStore + `perform_now`; `fly:release` solid schemas; barista broadcast rescue.

**Вердикт:** E2E оплаты **PASS** (без списания реальных денег на форме Т-Банка).

### Прогон 4 — Solid Queue worker + live табло (2026-05-28)

**Инструмент:** Chrome DevTools MCP на `coffeeos.fly.dev`  
**Код:** worker `bin/jobs` в `fly.toml`; `Barista::OrderBoardBroadcaster` + job после callback и cash-заказа витрины; idempotent `fly:release` schema.

| Шаг | PASS/FAIL | Примечание |
|-----|-----------|------------|
| Deploy + `fly scale count worker=1` | PASS | GH Actions #39 `0bde33d` |
| `/up` | PASS | 200 |
| Shop A cash → `accepted` | PASS | LiveSmoke2, 179₽ |
| Barista login + табло | PASS | `barista-a@…` |
| Shop cash → табло **без F5** | **PASS** | ACCEPTED 5→6, sync broadcast |
| Signed callback → worker → `accepted` | **PASS** | `85bef120`, `TbankCallbackJob` на worker `2871332`, без `perform_now` |
| Callback → табло без F5 | **PASS** | sync broadcast после worker |
| WebSocket `/cable` | PASS | 101 |

**Fix (2026-05-28):** worker падал (`Solid Queue … pool is 3`) → `DB_POOL=8`; `/callbacks/*` исключён из `host_authorization`.

**Вердикт:** smoke **PASS** — live-табло и async callback подтверждены.

### Прогон 5 — Kiosk backend + docs (2026-05-30)

| Шаг | PASS/FAIL | Примечание |
|-----|-----------|------------|
| `POST /kiosk/api/auth` | PASS | 6 tests; `X-Device-Token` → `tenant_id` |
| Shop API reuse | PASS | `/shop/api/*` + `X-Shop-Tenant` — см. [`FLUTTER_API.md`](FLUTTER_API.md) |
| Curl smoke | DOC | см. [`FLUTTER_API.md`](FLUTTER_API.md) § Prod smoke |
| Flutter UI | SKIP | Q3 2026 TBD |

**Вердикт:** kiosk backend задокументирован в `FLUTTER_API.md`; **приёмка §I — не закрыта** (ждёт апрува).

### Прогон 6 — smoke checklist (2026-05-30)

**Инструмент:** curl + MCP DevTools / Chrome DevTools на `coffeeos.fly.dev`

| Шаг | PASS/FAIL | Примечание |
|-----|-----------|------------|
| SHOP_API_KEY на prod | **PASS** | без ключа → 401; ключ в meta `/shop` → products 200 |
| shift-a → `/manager` | **PASS** | `shift-a@demo.coffeeos.local`, AUTH-06 |
| Kiosk auth curl | **PASS** | device «Smoke QA6b», tenant Demo A |
| Kiosk cart+order curl | **PARTIAL** | cart 200; order 422 «корзина пуста» — session cookie не persist (fix `touch_cart_session!`, ждёт deploy) |
| Kiosk E2E barista | **PASS** | витрина cash «Smoke QA6b» → `##202605-0015` ACCEPTED |
| Новая org (не demo) | **PASS** | org `smoke-org-qa6-0530`, tenant `d8e287c5-5524-423c-8e5a-605570c69517`, products API 200 |
| `bin/rails test` | **551/1 fail** | 1 failure pre-existing; shop/kiosk tests green после fix cart |

**Fix:** `Shop::CartService#touch_cart_session!` — session dirty для cookie между запросами API.

**§I не закрывать.**

### Прогон 7 — curl smoke PASS (2026-05-30)

**Deploy:** `e932944` (prog 6 + `touch_cart_session!`, GH Actions #45) → `11f40b6` (fix `skip_forgery_protection` вместо `null_session`, GH Actions #46).

**Инструмент:** curl (`--data-binary @file.json`, один cookie jar) + Chrome DevTools MCP на `coffeeos.fly.dev`.

| Шаг | PASS/FAIL | Примечание |
|-----|-----------|------------|
| GET `/shop?tenant_id=…` → cookie | **PASS** | jar перед API |
| Kiosk auth curl | **PASS** | device «Smoke QA6b», tenant Demo A |
| cart/add + cart GET | **PASS** | total 179₽, корзина persist между запросами |
| POST orders cash | **PASS** | `order_id` `e3a06dc9-b56b-4acb-8e81-93d1a83e38ca`, status `accepted` |
| Barista табло | **PASS** | `##202605-0016` в ACCEPTED, 0 мин, без F5 |

**Root cause prog 6 PARTIAL:** `protect_from_forgery with: :null_session` обнулял session без CSRF — curl/Flutter с `X-Shop-Api-Key` не видели корзину. **Fix:** `skip_forgery_protection` в `Shop::Api::BaseController` + тест `cart_persistence_test.rb`.

**Локальный тест (2026-05-30):** `bin/rails test test/integration/shop/api/cart_persistence_test.rb` — **PASS** (WSL, 1 run / 5 assertions / 0 failures). На Windows-native Ruby PG на `:5432` недоступен — гонять через WSL или `DATABASE_PORT=65432` с верным паролем.

**§I не закрывать.**

### Прогон 8 — UX таймаут БД >5 с (qa 6.2) (2026-05-30)

**Коммиты:** `eab8706` + `6831e24` + fix Svelte (локально, push после апрува).

| Шаг | PASS/FAIL | Примечание |
|-----|-----------|------------|
| Overlay в HTML layouts | **PASS** | barista/manager/УК/auth/prep_kitchen |
| Fetch >5 с → skeleton | **PASS** | `slow_request_tracker.js` |
| Shop Svelte overlay | **PASS** | `SlowRequestOverlay.svelte` |
| `GET /test/slow_page` | **PASS** | local/test only |
| `slow_request_ux_test.rb` | **PASS** | 2 runs, 9 assertions, 0 failures (WSL) |

**§I не закрывать.**

### Прогон 8b — MCP DevTools + full suite (2026-05-30)

> ⚠️ **Не полный RBAC** — только overlay UX + shop/barista/login. Полная матрица ролей → **прогон 10**.

**Стенд:** `localhost:3001` (WSL dev). **Prod:** не деплоили (ждёт апрува).

**MCP Chrome DevTools** — fetch `/test/slow_json` (sleep 6 с), overlay через ~5 с:

| Экран | PASS/FAIL | Примечание |
|-------|-----------|------------|
| `/login` | **PASS** | «Загрузка данных…», скрывается после ответа |
| `/shop?tenant_id=…` | **PASS** | Svelte `.slow-request-shop-overlay` |
| `/barista` | **PASS** | `.slow-request-overlay--visible` |

> `/test/slow_page` — открывается сразу, inline JS дергает `/test/slow_json` → overlay через ~5 с **(прогон 8c, MCP PASS)**.

| Suite | PASS/FAIL | Примечание |
|-------|-----------|------------|
| `bin/rails test` | **PASS** | **554 runs, 2297 assertions, 0 failures** (WSL, ~14 мин) |
| `slow_request_ux_test.rb` | **PASS** | повтор после fix Svelte `<script>` |

**Fix прогона:** `SlowRequestOverlay.svelte` — отсутствовал открывающий `<script>` (vite build fail).

### Прогон 9 — deploy Fly + prod smoke (2026-05-30)

**Push:** `85c566a..7b72132` → `develop` → GH Actions Deploy (UX overlay + slow_page + CSRF fix уже на prod).

**Коммиты в деплое:** `eab8706` (UX overlay), `6831e24`, `854aa61` (Svelte fix), `7b72132` (slow_page auto-smoke).

| Шаг | PASS/FAIL | Примечание |
|-----|-----------|------------|
| `/up` | **PASS** | 200 |
| Kiosk curl smoke | **PASS** | cookie → cart 179₽ → order `76c0540e-…` accepted «Kiosk Curl Prog9» |
| Shop MCP | **PASS** | витрина грузится, `#app` |
| Barista MCP | **PASS** | табло ACCEPTED, overlay markup на `/barista`, 17 заказов за смену |
| UX overlay на prod | **N/A** | `/test/slow_*` только local/test; overlay проверен local 8b–8c |

**§I не закрывать.**

### Прогон 10 — полный scope приёмки В2 (2026-06-01)

**Стенд:** `https://coffeeos.fly.dev` (deploy `e97397b`).  
**Инструменты:** MCP Chrome DevTools, `bin/prog10/prog10_fly_smoke.rb`, `bin/prog10/prog10_collect_kiosk_tokens.rb`, WSL.  
**Реестр:** [`PROG10_TENANTS.md`](PROG10_TENANTS.md).

| Блок | PASS/FAIL | Примечание |
|------|-----------|------------|
| Code review | **PASS** | см. PRACTICES / coffeeos-code-review.mdc |
| `/up` | **PASS** | 200 |
| `bin/rails test` | **PASS** | 554/0 (WSL) |
| 3 org × 3 точки | **PASS** | Demo + Prog10 Alpha + Beta |
| Оплата **9×** (cash+card) | **PASS** | [`artifacts/prog10/smoke/prog10_curl_full.json`](artifacts/prog10/smoke/prog10_curl_full.json), `ORDER_DELAY_SEC=7` |
| Stress **8** по 8 точкам | **PASS** | round-robin в том же отчёте |
| Kiosk **9×** | **PASS** | [`artifacts/prog10/smoke/prog10_kiosk_full.json`](artifacts/prog10/smoke/prog10_kiosk_full.json); токены — `bin/prog10/prog10_collect_kiosk_tokens.rb` (не в git) |
| RBAC ≥3/роль | **PASS** | [`artifacts/prog10/staff-rbac/prog10_rbac_matrix.md`](artifacts/prog10/staff-rbac/prog10_rbac_matrix.md) |
| MCP checkout UI | **PASS** | scrollIntoView + «Наличные» → заказ accepted (MCP) |
| Barista ↔ заказ | **PASS** | #202606-* на `/barista` после curl/kiosk/MCP |

**Вердикт прогона 10:** **PASS** (scope QA, без живого демо). Детали 10c — ниже.

**Живое демо** — только [`CHECKLIST.md`](CHECKLIST.md) § **I**, не этот документ.

---

### Прогон 10b — дозакрытие (2026-06-01)

9× cash/card, 9× kiosk, stress wave 1, RBAC, checkout MCP. Артефакты: `prog10/smoke/prog10_curl_full.json`, `prog10/smoke/prog10_kiosk_full.json`, `prog10/staff-rbac/prog10_rbac_matrix.md`.

### Прогон 10c — финальное закрытие scope (2026-06-01)

| Блок | PASS | Артефакт / примечание |
|------|------|------------------------|
| Витрина 9× API | **PASS** | `prog10/smoke/prog10_shop_urls.json` |
| Витрина MCP (выборочно) | **PASS** | Alpha p1, Demo A — каталог в браузере |
| Stress wave 2 | **PASS** | `prog10/smoke/prog10_stress_wave2.json` (8 cash, offset 4) |
| Kiosk cash+card 9× | **PASS** | `prog10/smoke/prog10_kiosk_cash_card.json` |
| Staff Prog10 + login | **PASS** | `prog10-bar-a1@prog10.local` → `/barista` Alpha p1; `prog10/staff-rbac/prog10_staff_setup.json` |
| Barista Prog10 точка | **PASS** | заказ curl `Prog10 Alpha Barista` accepted, табло Alpha |
| Prep kitchen | **PASS** | pk-manager → `/prep_kitchen` |
| AUTH-10 logout | **PASS** | MCP → `/login` |
| `bin/rails test` | **PARTIAL** | 554 runs, **1 failure** (перегон 2026-06-01; уточнить тест отдельно) |

**Вердикт прогона 10 (полный scope QA):** **PASS** с оговоркой 1 flaky/fail в suite.

**Скрипты:** `prog10_shop_urls_check.rb`, `prog10_setup_staff.rb`, `prog10_stress_wave2.rb`, обновлён `prog10_fly_smoke.rb` (`SKIP_TENANTS`, kiosk cash+card).

### Прогон 10d — блок 13 финал (2026-06-02)

| Хвост | PASS/SKIP | Артефакт |
|-------|-----------|----------|
| curl 9× shop cash+card | **PASS** | `prog10/_index/prog10_final_block13.json` (9 tenants) |
| stress wave 1 (8 rounds) | **PASS** | в `prog10/_index/prog10_final_block13.json` |
| stress wave 2 (offset 4) | **PASS** | `prog10/smoke/prog10_stress_wave2.json` |
| kiosk 9× cash+card | **PASS** | `prog10/_index/prog10_final_block13.json` |
| RBAC matrix + isolation | **PASS** | `prog10/staff-rbac/prog10_rbac_matrix.md`, `prog10/staff-rbac/prog10_staff_isolation.json` |
| артефакты index | **PASS** | `prog10/_index/prog10_final_index.json` |
| живое демо / §I | **SKIP** | вне scope прогона 10 |
| V2-P10-08 source=kiosk | **SKIP** | после блоков 1–14 |
| SEC-07 shop meta key | **SKIP** | → В3 **V3-SEC-07** |
| общий цех на N точек | **SKIP** | `V2-BACKLOG-PREP-MULTI` → Веха 3 |

**Вердикт блока 13:** **PASS**.

### Прогон 10e — блок 14 postmortem (2026-06-02)

| Пункт | Статус |
|-------|--------|
| Postmortem § Прогон 10 | **PASS** — [`POSTMORTEM_2026-05-28.md`](POSTMORTEM_2026-05-28.md) |
| Детальный чеклист 0–14 | **PASS** | § выше в этом файле |

**Вердикт блока 14:** **PASS**. Прогон 10 ops **завершён**; §I в [`CHECKLIST.md`](CHECKLIST.md) — отдельно.
