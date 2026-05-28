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
| Deploy + `fly scale count worker=1` | PASS | GH Actions run #36–37, commit `97baa77` |
| `/up` | PASS | 200 |
| Shop A cash → `accepted` | PASS | order `c85849ad-…`, 179₽, Smoke Test |
| Barista login + табло | PASS | `barista-a@…`, 4+ заказов в ACCEPTED |
| Shop cash → табло **без F5** | ⏸ | retest после deploy worker (barista открыли после заказа) |
| Callback → табло без F5 | ⏸ | не прогоняли в этом прогоне |
| Worker logs — job processed | ⏸ | проверить в Fly logs worker |

**Вердикт:** smoke **частичный PASS** — витрина→cash→accepted OK; live-табло — повтор после деплоя worker.
