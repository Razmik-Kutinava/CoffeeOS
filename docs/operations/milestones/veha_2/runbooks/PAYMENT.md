# Оплата — Веха 2

**Приоритет:** сразу после онбординга (витрина + QR на столах). **Чеклист:** [`CHECKLIST.md`](CHECKLIST.md) § C.

---

## Зачем

Демо В1 — имитация. В2 — **реальные деньги** на витрине (и киоске тем же pipeline), чтобы точку можно было открыть с QR без доработки POS.

---

## Как сейчас (В1)

| Env | Поведение |
|-----|-----------|
| `SHOP_SIMULATE_PAYMENT=1` (default) | Заказ сразу `accepted`, payment `succeeded`, provider `shop` |
| `SHOP_SIMULATE_PAYMENT=0` | card/sbp → `pending_payment`, payment `pending` — **ждёт callback** |

**Код:** `Shop::OrderCreator`, `Callbacks::PaymentStatusUpdater`, `Callbacks::EventsController#payment`.

**Тесты:** `test/services/shop/order_creator_test.rb`, `test/integration/shop/api/mvp_flow_test.rb`, `test/controllers/callbacks/events_controller_test.rb`.

---

## Целевой поток В2

```
Клиент (shop/QR) → create order pending_payment
  → redirect/widget шлюза (ЮKassa — целевой провайдер в qa)
  → callback POST /callbacks/payments
  → PaymentStatusUpdater → accepted → списание склада (триггер + OrderRecipeDeduction)
```

---

## Задачи реализации

- [x] Адаптер провайдера Т-Банк — `app/services/payments/tbank_adapter.rb` *(2026-05-28)*
- [x] `OrderCreator` вызывает адаптер при `pending_payment`, сохраняет `provider_payment_id`, возвращает `payment_url` *(2026-05-28)*
- [x] `Shop::Api::OrdersController` — возвращает `payment_url` в JSON ответе *(2026-05-28)*
- [x] Callback: `Callbacks::TbankController` + `POST /callbacks/tbank` — верификация Token, маппинг статусов *(2026-05-28)*
- [x] `PaymentStatusUpdater` — добавлено `Inventory::OrderRecipeDeduction` при `succeeded` *(2026-05-28)*
- [x] Тесты: `test/services/payments/tbank_adapter_test.rb` (11 тестов), `test/controllers/callbacks/tbank_controller_test.rb` (8 тестов) *(2026-05-28)*
- [x] Витрина: выбор card/sbp/cash, редирект на `payment_url`, без double-submit *(2026-05-28)*
- [x] Staging: `SHOP_SIMULATE_PAYMENT=0` + тестовый ключ DEMO на Fly *(2026-05-28, `fly secrets set`)*
- [x] Manager: pending payments при закрытии смены — CloseWizard показывает pending онлайн-платежи за 24ч (не блокируют закрытие) *(2026-05-28)*
- [ ] Киоск: reuse shop payment flow — [`KIOSK.md`](KIOSK.md) *(ждёт Flutter)*
- [x] ⭐ **Outbox + Circuit Breaker** — [`CHECKLIST.md`](CHECKLIST.md) §H *(2026-05-28, commit `0338a3e`)*
- [x] ⭐ Переключить на боевой терминал (`TBANK_TERMINAL_KEY=1719235292309`) — *(2026-05-28, prod smoke PASS)*

---

## ENV (черновик)

| Переменная | Назначение |
|------------|------------|
| `SHOP_SIMULATE_PAYMENT` | `0` на боевом приёмочном стенде |
| `CALLBACK_SHARED_SECRET`, `CALLBACK_SHARED_TOKEN` | Секреты callback (для `Callbacks::EventsController`) |
| `TBANK_TERMINAL_KEY` | TerminalKey терминала (тест: `1719235292292DEMO`) |
| `TBANK_PASSWORD` | Password терминала |
| `TBANK_RETURN_URL` | Базовый URL приложения для SuccessURL/FailURL (напр. `https://coffeeos.fly.dev`) |
| `TBANK_TAXATION` | Система налогообложения в Receipt 54-ФЗ (`osn`, `usn_income`, …); default `usn_income` |
| `TBANK_TAX` | НДС позиции чека (`none`, `vat20`, …); default `none` |

Не коммитить секреты.

### Receipt 54-ФЗ (2026-07-27, Шаг 1 SBP эпик)

- `Payments::TbankReceiptBuilder` → объект `Receipt` (Items, Taxation) для Init.
- `TbankAdapter#init_payment(..., receipt:)` кладёт Receipt в payload; **Token** считается без nested Hash/Array (канон Т-Кассы).
- Подключение Receipt в OrderCreator / SBP init — следующие шаги эпика.

### GetQr / SBP deep link (2026-07-27, Шаг 2)

- `Payments::TbankQrFetcher` → `POST /v2/GetQr` с `DataType=PAYMENT_LINK` → `{ payment_url: Data }` (`https://qr.nspk.ru/...`).
- Оркестрация Init→GetQr — `Shop::SbpPaymentInitiator` (Шаг 3).

### SBP init endpoint (2026-07-27, Шаг 3)

- `POST /shop/api/payments/sbp/init` `{ order_id }` → `{ payment_url }` (nspk deep link).
- `Shop::SbpPaymentInitiator`: simulate → fictional nspk; live → Receipt+Init+GetQr.
- Заказ должен быть `pending_payment` тенанта; 404/422/500 по `Error#http_status`.

### SBP UI «Оплатить быстро» (2026-07-27, Шаг 9)

- FE: `shopSbpPay.js` → `POST /shop/api/payments/sbp/init` → `window.location` только на `*.nspk.ru`.
- Checkout: `POST /orders` `payment_method=sbp` (всегда `pending_payment`, без Init в OrderCreator) → sbp/init → redirect.
- CTA: «Оплатить быстро»; loading: «Оплата через СБП…». Poll return 2s×30 — Шаг 11.

### SBP return polling (2026-07-27, Шаг 11)

- `pollSbpPaymentStatus` → `POST /orders/:id/finalize`, интервал **2с × 30** (60с).
- SuccessURL/`status=ok|success` → poll → `/order/:id`; timeout / cancelled / fail → «Оплата не завершена, попробовать снова».
- `PaymentResult.svelte` — без бесконечного Loading (`finally` снимает loader).

### Card tokenization characterization (2026-07-27, Шаги 7–8)

- Init `Recurrent=Y` + `SavedCardStore` → `mobile_payment_methods.card_token` (= RebillId).
- Charge `/v2/Charge` + `POST /shop/api/payments/one_click`; invalid token → **422** + `error_code` (FE `isInvalidRebillPaymentError`).
- Тесты: `sbp_epic_card_tokenization_char_test.rb` (+ step2/step4/adapter).

---

## Итог реализации (2026-05-28)

Интеграция Т-Банк эквайринг полностью реализована:

- **Провайдер:** Т-Банк (магазин CODE BLACK, ООО КЛАУДКАФЕ)
- **Терминал тест:** `1719235292292DEMO` → прод: `1719235292309`
- **Флоу:** витрина → `OrderCreator` → `TbankAdapter#init_payment` → `PaymentURL` → редирект → Т-Банк форма → callback `POST /callbacks/tbank` → `PaymentStatusUpdater` → order `accepted` → списание склада
- **Протестировано:** браузерный тест — редирект на `https://pay.tbank.ru/x77ZGOty`, сумма 179₽ передана корректно
- **Тесты:** 541 runs, 0 failures (TbankAdapter x11, TbankController x8)
- **Manager:** CloseWizard показывает pending online-платежи за 24ч (информационно, не блокируют)

## Smoke pre-prod (2026-05-28, Chrome DevTools MCP)

**Стенд:** `coffeeos.fly.dev`, DEMO-терминал, `SHOP_SIMULATE_PAYMENT=0`  
**UUID витрин:** см. [`../veha_1/DEMO_LOGINS.md`](../veha_1/DEMO_LOGINS.md) — **не** локальный `8c7f5bc7-…` из qa_scenarios.

| # | Сценарий | Результат |
|---|----------|-----------|
| 1 | `/up` | ✅ 200 |
| 2 | `bin/rails test` | ✅ 541 runs, 0 failures |
| 3 | Витрина A `?tenant_id=2fdee1ac-…` — каталог | ✅ товары, 179₽ |
| 4 | Витрина B `?tenant_id=655aaccb-…` — каталог | ✅ другие цены (189₽), изоляция |
| 5 | Корзина → checkout UI | ✅ |
| 6 | Заказ **cash** → `accepted` | ✅ order `c5ffaf41-…`, 179₽ |
| 7 | Заказ **card** → `payment_url` → pay.tbank.ru | ✅ *(2026-05-28 после `884cdea`)* order `f40fb10d-…`, 179₽ |
| 8 | Manager `shift-a@…` → `/manager` | ✅ дашборд, витрина в sidebar |
| 9 | Полный callback T-Bank (оплата картой) | ⏸ не прогоняли — блокер п.7 |

**Вердикт:** pre-prod smoke **PASS** — готовы к переключению на боевой терминал после апрува заказчика.

## Smoke prod (2026-05-28, Chrome DevTools MCP)

**Стенд:** `coffeeos.fly.dev`, **боевой** терминал `1719235292309`, `SHOP_SIMULATE_PAYMENT=0`  
**Переключение:** `fly secrets set TBANK_TERMINAL_KEY=1719235292309 TBANK_PASSWORD=… TBANK_RETURN_URL=https://coffeeos.fly.dev SHOP_SIMULATE_PAYMENT=0 -a coffeeos` (пароль только в Fly secrets, не в репо).

| # | Сценарий | Результат |
|---|----------|-----------|
| 1 | `/up` после rolling deploy | ✅ 200 |
| 2 | Payment tests (47 runs) | ✅ 0 failures |
| 3 | Shop A — card Init → `payment_url` | ✅ order `25bb9312-…`, `https://pay.tbank.ru/EJe3CaXH` |
| 4 | Форма Т-Банка (prod) | ✅ **179₽**, «Оплата картой» |
| 5 | Shop A — cash → `accepted` | ✅ order `c36b2de4-…`, 179₽ |
| 6 | Полная оплата картой (реальные деньги) | ⏸ тест-карта на prod → `ACTIVATION_ERROR` (ожидаемо) |
| 7 | Callback CONFIRMED → `accepted` | ✅ order `f8427fc4-…`, PaymentId `8576370191`, `perform_now` fallback |
| 8 | Барista табло — заказ в колонке ACCEPTED | ✅ `##202605-0008`, 179₽ |
| 9 | Барista «Принять →» | ✅ после fix broadcast (Solid Cable schema) |

**Вердикт:** prod smoke **PASS** — боевой терминал, Init, callback→accepted, заказ на табло барista.

### E2E prod (прогон 3, 2026-05-28)

**Цепочка:** витрина card → `pay.tbank.ru` → webhook CONFIRMED → order `accepted` → барista board.

| Шаг | ID / детали | PASS |
|-----|-------------|------|
| Card Init | `f8427fc4-…`, `https://pay.tbank.ru/roEOwCZL` | ✅ |
| Форма 179₽ | prod terminal CODE BLACK | ✅ |
| Тест-карта 2201382000000013 | `ACTIVATION_ERROR` на prod | ⏸ *(нужна реальная карта)* |
| CheckOrder → PaymentId | `8576370191` | ✅ |
| POST `/callbacks/tbank` CONFIRMED | HTTP 200 `{ok:true}` | ✅ |
| Payment status | `succeeded`, order `accepted` | ✅ |
| Barista `barista-a@…` | заказ `##202605-0008` в ACCEPTED | ✅ |
| `bin/rails test` | 544 runs, 0 failures | ✅ |

**Fixes в прогоне:** idempotency на MemoryStore; callback `perform_now` если Solid Queue недоступен; `fly:release` load queue/cable schema; barista broadcast не роняет 500.

### Прогон 4 — Solid Queue + live табло (2026-05-28)

**Код (commit TBD):**
- `fly.toml`: processes `web` + `worker` (`bin/jobs`); после деплоя `fly scale count worker=1`
- `Barista::OrderBoardBroadcaster` — Turbo Streams на канбан
- `Barista::BroadcastOrderBoardJob` — после callback оплаты и cash-заказа витрины
- `fly:release` — schema queue/cache/cable только если таблиц ещё нет
- `production.rb` — Action Cable URL/origins для Fly
- Цех ↔ точка — [`../veha_3/CHECKLIST.md`](../veha_3/CHECKLIST.md) §A

| Шаг | PASS/FAIL | Примечание |
|-----|-----------|------------|
| Deploy + worker=1 | PASS | CI #39 |
| Shop cash → барista без F5 | **PASS** | sync `OrderBoardBroadcaster` (`0bde33d`) |
| Worker crash loop (pool 3 < SQ 5) | **FIX** | `DB_POOL=8` в `fly.toml` + `database.yml` |
| Signed callback → worker | **PASS** | `fly:callback_smoke`: order `85bef120` → `accepted`, `[TbankCallbackJob] Processed` на worker |
| Callback → барista без F5 | **PASS** | sync broadcast в `PaymentStatusUpdater` |

**Вердикт:** live-табло + async callback **PASS**. Retest: `fly machine exec <web> -a coffeeos --timeout 120 -j '/bin/bash -lc "cd /rails && bin/rake fly:callback_smoke"'`

## Не в scope этого дока

- Фискализация / ОФД — отдельные callbacks, частично в schema
- Оплата **наличными на barista POS** — уже в В1 (не шлюз витрины)

---

## QA

`docs/agents/AGENTS/qa_scenarios.md` — секция **[ВЕХА 2] Реальная оплата**.
