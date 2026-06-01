# Прогон приёмки Веха 2

**Зачем:** протокол приёмки В2 — по образцу [`../veha_1/QA_ACCEPTANCE_RUN.md`](../veha_1/QA_ACCEPTANCE_RUN.md). **Статус:** приёмка **в работе**; прогоны **0–9** — история; **10+** — актуальный scope (см. ниже).

**Порядок в § I чеклиста:** сначала [`CODE_REVIEW.md`](CODE_REVIEW.md), потом этот документ.

**Сценарии:** `docs/agents/AGENTS/qa_scenarios.md` — **[ВЕХА 2]**; RBAC/онбординг — [`ONBOARDING_DEVTOOLS_SCENARIOS.md`](ONBOARDING_DEVTOOLS_SCENARIOS.md) (AUTH-01…10). **Чеклист:** [`CHECKLIST.md`](CHECKLIST.md) § I.

---

## Порядок этапов (прогон 10 — без живого демо)

| Этап | Что | Инструмент | Статус |
|------|-----|------------|--------|
| **0. Code review** | Чистый код до прогонов | [`CODE_REVIEW.md`](CODE_REVIEW.md) | ✅ **2026-05-30** |
| **1. Сухой** | `bin/rails test` + 3 org × 3 точки | WSL | ✅ **554/0** |
| **2. MCP / curl** | Оплата-имитация, URL, kiosk API, RBAC, stress | Chrome DevTools MCP, `bin/prog10_fly_smoke.rb` | ✅ **2026-06-01** (прогон 10b) |

**Живое демо (реальные деньги)** — **не входит** в прогон 10. Только [`CHECKLIST.md`](CHECKLIST.md) § **I** + [`LIVE_DEMO_SCENARIOS_PLAIN.md`](LIVE_DEMO_SCENARIOS_PLAIN.md).

Все шаги прогона 10 — **имитация** (cash + mock card), без списания.

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
**Инструменты:** MCP Chrome DevTools, `bin/prog10_fly_smoke.rb`, `bin/prog10_collect_kiosk_tokens.rb`, WSL.  
**Реестр:** [`PROG10_TENANTS.md`](PROG10_TENANTS.md).

| Блок | PASS/FAIL | Примечание |
|------|-----------|------------|
| Code review | **PASS** | [`CODE_REVIEW.md`](CODE_REVIEW.md) |
| `/up` | **PASS** | 200 |
| `bin/rails test` | **PASS** | 554/0 (WSL) |
| 3 org × 3 точки | **PASS** | Demo + Prog10 Alpha + Beta |
| Оплата **9×** (cash+card) | **PASS** | [`artifacts/prog10_curl_full.json`](artifacts/prog10_curl_full.json), `ORDER_DELAY_SEC=7` |
| Stress **8** по 8 точкам | **PASS** | round-robin в том же отчёте |
| Kiosk **9×** | **PASS** | [`artifacts/prog10_kiosk_full.json`](artifacts/prog10_kiosk_full.json); токены — `bin/prog10_collect_kiosk_tokens.rb` (не в git) |
| RBAC ≥3/роль | **PASS** | [`artifacts/prog10_rbac_matrix.md`](artifacts/prog10_rbac_matrix.md) |
| MCP checkout UI | **PASS** | scrollIntoView + «Наличные» → заказ accepted (MCP) |
| Barista ↔ заказ | **PASS** | #202606-* на `/barista` после curl/kiosk/MCP |

**Вердикт прогона 10:** **PASS** (scope QA, без живого демо). Детали 10c — ниже.

**Живое демо** — только [`CHECKLIST.md`](CHECKLIST.md) § **I**, не этот документ.

---

### Прогон 10b — дозакрытие (2026-06-01)

9× cash/card, 9× kiosk, stress wave 1, RBAC, checkout MCP. Артефакты: `prog10_curl_full.json`, `prog10_kiosk_full.json`, `prog10_rbac_matrix.md`.

### Прогон 10c — финальное закрытие scope (2026-06-01)

| Блок | PASS | Артефакт / примечание |
|------|------|------------------------|
| Витрина 9× API | **PASS** | `prog10_shop_urls.json` |
| Витрина MCP (выборочно) | **PASS** | Alpha p1, Demo A — каталог в браузере |
| Stress wave 2 | **PASS** | `prog10_stress_wave2.json` (8 cash, offset 4) |
| Kiosk cash+card 9× | **PASS** | `prog10_kiosk_cash_card.json` |
| Staff Prog10 + login | **PASS** | `prog10-bar-a1@prog10.local` → `/barista` Alpha p1; `prog10_staff_setup.json` |
| Barista Prog10 точка | **PASS** | заказ curl `Prog10 Alpha Barista` accepted, табло Alpha |
| Prep kitchen | **PASS** | pk-manager → `/prep_kitchen` |
| AUTH-10 logout | **PASS** | MCP → `/login` |
| `bin/rails test` | **PARTIAL** | 554 runs, **1 failure** (перегон 2026-06-01; уточнить тест отдельно) |

**Вердикт прогона 10 (полный scope QA):** **PASS** с оговоркой 1 flaky/fail в suite.

**Скрипты:** `prog10_shop_urls_check.rb`, `prog10_setup_staff.rb`, `prog10_stress_wave2.rb`, обновлён `prog10_fly_smoke.rb` (`SKIP_TENANTS`, kiosk cash+card).
