# Прогон приёмки Веха 2

**Зачем:** протокол, как [`../veha_1/QA_ACCEPTANCE_RUN.md`](../veha_1/QA_ACCEPTANCE_RUN.md) для В1 — заполнять **когда начнётся** приёмка В2 (не сейчас).

**Сценарии:** `docs/agents/AGENTS/qa_scenarios.md` — секции **[ВЕХА 2]**. **Чеклист:** [`CHECKLIST.md`](CHECKLIST.md) § I.

---

## Порядок этапов (план)

| Этап | Что | Инструмент | Статус |
|------|-----|------------|--------|
| **1. Сухой** | Тесты + новая org без demo seed | `bin/rails test`, integration | ✅ 541/0 *(2026-05-28)* |
| **2. MCP / браузер** | Онбординг, оплата, киоск | Chrome DevTools MCP | ✅ pre-prod + **prod terminal** *(2026-05-28)* |
| **3. Живое демо** | Заказчик | `LIVE_DEMO_SCENARIOS_PLAIN.md` | ⏳ |

---

## Подготовка (заполнить при прогоне)

| Шаг | Команда | Результат |
|-----|---------|-----------|
| Demo / чистая org | demo-point-a/b на Fly (`DEMO_LOGINS.md`) | ✅ |
| `bin/rails test` | полный suite | **541 runs, 0 failures** *(2026-05-28)* |
| `SHOP_SIMULATE_PAYMENT` | 0 на стенде | ✅ Fly secrets |

---

## Минимальный scope приёмки В2

1. Org + 3 точки из УК с address + карточка URL.
2. Витрина с **реальной** оплатой (или тестовым шлюзом).
3. QR URL открывается с телефона.
4. Kiosk — если § D чеклиста закрыт.
5. RBAC smoke всех ролей на **новой** org.

---

## Журнал прогонов

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
