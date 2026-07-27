# todo — СБП Deep Link + токенизация карт (Т-Касса v2) · CODE:BLACK

> **ТЗ:** [`customer_tasks/Интеграция оплаты СБП Deep Link и токенизации карт Т-Касса v2.md`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20оплаты%20СБП%20Deep%20Link%20и%20токенизации%20карт%20Т-Касса%20v2.md)  
> **Артефакты:** [`artifacts/sbp_deep_link_card_tokenization/`](../milestones/veha_2/artifacts/sbp_deep_link_card_tokenization/)  
> **Runbook:** [`runbooks/PAYMENT.md`](../milestones/veha_2/runbooks/PAYMENT.md)

## Текущая фаза

**PHASE 2: GREEN** — `[x]` Шаг 2 GetQr · qr+adapter 28/0 · дальше RED Шаг 3 `sbp/init`

---

## Маппинг путей ТЗ → CoffeeOS

| ТЗ | Канон CoffeeOS | Решение SPEC |
|----|----------------|--------------|
| `POST /api/v1/payments/sbp/init` | `POST /shop/api/payments/sbp/init` | **новый** route + тонкий controller + сервис |
| `POST /api/v1/payments/webhook` | `POST /callbacks/tbank` | **уже есть** — не дублировать |
| `GET /api/v1/payments/status/:order_id` | `GET /shop/api/orders/:id` + `POST .../finalize` | **reuse**; опционально тонкий alias `GET /shop/api/payments/status/:order_id` |
| Jest / Vitest / React paths | `test/services/…`, `test/integration/…`, `test/javascript/*.mjs` + Svelte | стек **Rails 8 + Svelte** |
| `SecretKey` | `TBANK_PASSWORD` | один Password терминала для Token; хардкод запрещён |

---

## As-is (2026-07-27)

| Область | Сейчас | Файлы | Строк |
|---------|--------|-------|------:|
| Init | `TbankAdapter#init_payment` — Amount/OrderId/URLs/CustomerKey/Recurrent; **без Receipt** | `app/services/payments/tbank_adapter.rb` | 228 ⚠ |
| GetQr / NSPK | **нет** | — | — |
| Charge / Recurrent | `charge`, `charge_recurrent`; NewCard `Recurrent=Y`; one_click | adapter + `shop/one_click_payment_service.rb` + `new_card_payment_service.rb` | ok |
| Token SHA-256 | `build_token` / `verify_notification` (sort + Password + SHA-256) | adapter | ok |
| Webhook | `Callbacks::TbankController` → job → `PaymentStatusUpdater`; idempotency `CacheCounter`; invalid Token → **401** (не 403) | `callbacks/tbank_controller.rb` | 80 |
| RebillId | webhook → `SavedCardStore` → `MobilePaymentMethod` | `payments/saved_card_store.rb` | ok |
| SBP API | `payment_method: sbp` в OrderCreator → обычный `PaymentURL`, не deep link | `shop/order_creator.rb` | 392 ⚠ |
| Shop payments API | `new_card`, `one_click`, `card_config`; **нет** `sbp/init` | `shop/api/payments_controller.rb` | 57 |
| Status / poll | finalize + Cable; settle **1.2s × 25 (~30s)** | `shopPaySettle.js`, `orders#finalize` | 74 |
| UI SBP | disabled + тост «СБП временно недоступно» | `PaymentMethodsSheet.svelte` | 372 ⚠ |
| 1-tap карта | маска `Картой *XXXX` + one_click + invalid-token UX | sheet + `repeatInvalidTokenStore.js` | ok |
| Iframe | legacy `tbankPayment.js`; happy path — FinishAuthorize / Charge | **не использовать** в этом эпике | — |

**CSP:** `*.nspk.ru` уже разрешён.

---

## Gap → решения SPEC

| # | Gap | Решение | Не делать |
|---|-----|---------|-----------|
| G1 | Нет Receipt 54-ФЗ | Новый `Payments::TbankReceiptBuilder` → hash `Receipt` (Items, Taxation). `init_payment` принимает опциональный `receipt:` и кладёт в payload **до** Token. Структура Items/Taxation — как требует Т-Касса; не ломать поля. | Хардкод Taxation без конфига; менять чужие Init без теста |
| G2 | Нет GetQr | Новый `Payments::TbankQrFetcher#call(payment_id:)` → `POST /v2/GetQr` `DataType=PAYMENT_LINK` → `Data` (`https://qr.nspk.ru/...`). **Не** раздувать `tbank_adapter.rb` (уже 228). | Копипаста Token/HTTP в третий раз — переиспользовать `build_token`/`post_json` через adapter instance methods или thin delegate |
| G3 | Нет SBP init endpoint | `Shop::SbpPaymentInitiator#call!(order:)`: Init (с Receipt) → GetQr → `{ payment_url: Data }`. Route `POST /shop/api/payments/sbp/init` (`order_id`). Controller тонкий. Simulate: при `SHOP_SIMULATE_PAYMENT=1` — фиктивный nspk-like URL **или** сразу settled (зафиксировать в RED). | Новый `/api/v1/...` namespace |
| G4 | Webhook 401 vs 403 | Оставить **401** как канон проекта (уже тесты). В отчёте SPEC: отклонение от ТЗ осознанное. Идемпотентность уже есть. | Дублирующий `POST .../webhook` |
| G5 | Status GET | MVP: документировать `GET orders/:id` + finalize. Если приёмка требует литерал — тонкий `GET /shop/api/payments/status/:order_id` → тот же JSON статуса. | Long-poll на сервере |
| G6 | Steps 7–8 | **Characterization**: тесты подтверждают Recurrent + Charge + SavedCardStore. Код не переписывать, кроме дыр из ISSUES (delayed RebillId — **вне** MVP этого эпика, уже в ISSUES). | Wipe UserCards / новый iframe |
| G7 | UI «Оплатить быстро» | Включить SBP в sheet: убрать disabled; CTA → `sbp/init` → Loading (монохром) → `window.location.href = payment_url`. Ошибки 400/500 — терминальный inline/toast, **не** бесконечный Loading. Логику вынести в `lib/shopSbpPay.js` (sheet 372 строк — не раздувать). | iframe Т-Банка |
| G8 | 1-tap карта | Уже есть; мелкий polish копирайта/маски `**** 1234` vs `Картой *XXXX` — только если ломает приёмку. Invalid token — reuse `repeatInvalidTokenStore`. | Новый BottomSheet |
| G9 | Return + polling 60s/2s | SBP return → `#/payment-result` (существующие Success/Fail URL). Для SBP-пути: poll **2000 ms × 30** (60s) через параметры/`shopSbpPay.js` (не ломать one_click settle 1.2s×25). Timeout / CANCELED / REJECTED → экран «Оплата не завершена». | Бесконечный Loading |

### Ограничения ТЗ (соблюдать)

- Нет iframe/UI-виджета Т-Банка.
- `RebillId` / `CustomerKey` только в БД / серверном контексте (не localStorage plaintext).
- Receipt Items/Taxation не ломать под 54-ФЗ.
- Password только из `TBANK_PASSWORD`.
- Нет бесконечного Loading.

### File-size / RLS

| Файл | Лимит | План |
|------|-------|------|
| `tbank_adapter.rb` (228) | стоп >200 | GetQr + Receipt **в новых** файлах; в adapter — минимум (опц. `receipt:` в Init) |
| `PaymentMethodsSheet.svelte` (372) | legacy | только вызов lib + enable SBP row |
| `order_creator.rb` (392) | не трогать в MVP SBP | SBP идёт через отдельный initiator после созданного order |
| RLS | — | `sbp/init` только с `Current.tenant_id` shop session; order принадлежит tenant |

**DDL / Migration Gate:** не требуется для MVP (RebillId уже в `mobile_payment_methods`).

---

## Волны реализации (после SPEC)

| Волна | Шаги ТЗ | Суть |
|-------|---------|------|
| **A** | 1–3 | Receipt + GetQr + `POST .../sbp/init` |
| **B** | 4–6 | Characterization webhook Token + status alias (если нужен) |
| **C** | 7–8 | Characterization Recurrent/Charge (без новой логики) |
| **D** | 9–11 | UI SBP + return polling 60s/2s |

Каждый шаг = RED → GREEN → регрессия зоны оплаты (§2.3). **Первый RED после go:** Шаг 1 (Receipt/Init payload).

---

## Файлы (план GREEN, по волнам)

### Волна A

| Файл | Действие |
|------|----------|
| `app/services/payments/tbank_receipt_builder.rb` | **create** |
| `app/services/payments/tbank_qr_fetcher.rb` | **create** |
| `app/services/shop/sbp_payment_initiator.rb` | **create** |
| `app/services/payments/tbank_adapter.rb` | **extend** минимально: `receipt:` в Init |
| `app/controllers/shop/api/payments_controller.rb` | `sbp_init` |
| `config/routes.rb` | `post payments/sbp/init` |
| `test/services/payments/tbank_receipt_builder_test.rb` | RED→GREEN |
| `test/services/payments/tbank_qr_fetcher_test.rb` | RED→GREEN |
| `test/services/shop/sbp_payment_initiator_test.rb` | RED→GREEN |
| `test/integration/shop/api/sbp_payment_init_test.rb` | RED→GREEN |

### Волна B–C

| Файл | Действие |
|------|----------|
| `test/controllers/callbacks/tbank_controller_test.rb` | extend: подделка Token |
| `test/integration/shop/api/payment_status_test.rb` | optional alias |
| existing one_click / usercards / adapter tests | characterization |

### Волна D

| Файл | Действие |
|------|----------|
| `app/frontend/lib/shopSbpPay.js` | **create** — init + redirect + poll opts |
| `app/frontend/lib/shopPaySettle.js` | optional configurable interval/max |
| `app/frontend/components/PaymentMethodsSheet.svelte` | enable SBP |
| `app/frontend/routes/Checkout.svelte` | wire SBP |
| `app/frontend/routes/PaymentResult.svelte` | fail/timeout copy |
| `test/javascript/shop_sbp_pay_test.mjs` | unit |
| `test/integration/shop/sbp_payment_ui_test.rb` | mirror/grep |

---

## Чеклист TDD (из ТЗ)

### Сценарий 1 — Init / GetQr / SBP init
- [x] Шаг 1: Init + Receipt 54-ФЗ (builder + payload; 400/500) — **GREEN**
- [x] Шаг 2: GetQr `PAYMENT_LINK` → `qr.nspk.ru` (400/500) — **GREEN**
- [ ] Шаг 3: `POST /shop/api/payments/sbp/init` → `{ payment_url }`

### Сценарий 2 — Webhook / status
- [ ] Шаг 4: SHA-256 Token — подделка → reject (канон **401**)
- [ ] Шаг 5: Webhook CONFIRMED/… + идемпотентность — **characterization** `/callbacks/tbank`
- [ ] Шаг 6: Status fallback — orders show/finalize (± alias)

### Сценарий 3 — Карта / токен
- [ ] Шаг 7: Recurrent → RebillId в БД — **characterization**
- [ ] Шаг 8: Charge one_click — **characterization** + ошибки невалидного токена

### Сценарий 4 — UI CODE:BLACK
- [ ] Шаг 9: «Оплатить быстро» / SBP → init → redirect
- [ ] Шаг 10: маска карты + 1-tap (polish при необходимости)
- [ ] Шаг 11: return + polling ≤60s / 2s; нет infinite Loading

---

## Тесты / регрессия

| Зона | Команда |
|------|---------|
| Новые unit | `bin/rails test test/services/payments/tbank_receipt_builder_test.rb test/services/payments/tbank_qr_fetcher_test.rb test/services/shop/sbp_payment_initiator_test.rb` |
| Оплата §2.3 | по `coffeeos-dev-gates.mdc` (payment cart + stage5 + order_creator) |
| T-Bank callback | `bin/rails test test/controllers/callbacks/tbank_controller_test.rb test/services/payments/tbank_adapter_test.rb` |
| JS | `node --test test/javascript/shop_sbp_pay_test.mjs` |

---

## Риски

| Риск | Митигация |
|------|-----------|
| GetQr недоступен на DEMO-терминале | stub HTTP в unit; MCP на Fly с боевым/тестовым ключом |
| Receipt отвергнут банком (Taxation/FFD) | конфиг Taxation из env/`PaymentConfig`; тест спецсимволов в имени товара |
| Двойной Init (OrderCreator + sbp/init) | initiator работает по **уже созданному** `pending_payment` order; не создавать второй Order |
| `tbank_adapter` ещё толще | GetQr/Receipt вне файла; при касании >+20 строк — план сплита + go |
| Путаница iframe PaymentURL vs NSPK | SBP только `Data` из GetQr; card path без iframe |

---

## Exit (из ТЗ + проект)

1. Зелёные тесты шагов + регрессия зоны оплаты.
2. Rubocop на изменённый Ruby (ESLint/tsc из ТЗ — N/A для Svelte path; JS — node:test).
3. Ручная/MCP: `qr.nspk.ru` deep link, банк picker, Charge по RebillId.
4. Апрув заказчика / CHECKLIST `[x]` — только после MCP + «ок».
