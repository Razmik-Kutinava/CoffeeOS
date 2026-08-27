# Bridge: Т-Банк (эквайринг, карты, СБП)

| Роль | Путь |
|------|------|
| Адаптер | `app/services/payments/tbank_adapter.rb` |
| Webhook | `POST /callbacks/tbank` → `Callbacks::TbankController#notify` |
| Job | `Payments::TbankCallbackJob` (retry ×5, `:critical`) |
| Статус | `Callbacks::PaymentStatusUpdater` |
| Карты | `Payments::SavedCardStore` → `mobile_payment_methods` |
| СБП QR | `Payments::TbankQrFetcher` → `/v2/GetQr` |
| СБП autopay | `Payments::TbankSbpAutopay#charge_qr`, `SbpAccountTokenFromWebhook` |
| GetState/Confirm | `Payments::TbankPaymentSync` |
| Init витрина | `WidgetPaymentInitiator`, `SbpPaymentInitiator`, `NewCardPaymentService`, `OneClickPaymentService` |

Shop API mapping: [`shop-api.md`](shop-api.md)

---

## T-Bank API methods (adapter)

| Method | Наш wrapper | Когда |
|--------|-------------|-------|
| `/v2/Init` | `init_payment` | new card, SBP, widget, recurrent bind |
| `/v2/FinishAuthorize` | `finish_authorize` | new_card + CardData (non-PCI) |
| `/v2/Charge` | `charge` / `charge_recurrent` | one_click RebillId |
| `/v2/GetState` | `get_payment_state` | poll, sync, RebillId fallback |
| `/v2/Confirm` | `confirm_payment` | AUTHORIZED → CONFIRMED (inline status) |
| `/v2/Cancel` | `cancel_payment` | guest cancel + refund (#40) |
| `/v2/GetQr` | `TbankQrFetcher` | SBP deep link `qr.nspk.ru` |
| `/v2/ChargeQr` | `TbankSbpAutopay#charge_qr` | SBP zero-click autopay |

Base URL: `https://securepay.tinkoff.ru/v2/`

---

## Shop payment matrix

| Shop endpoint | Flow | T-Bank chain | UX задача |
|---------------|------|--------------|-----------|
| `POST payments/new_card` | Новая карта + save_card | Init (+Receipt) → FinishAuthorize → webhook RebillId | UserCards |
| `POST payments/one_click` | Saved card | Init → Charge | Inline FSM, Quick Repeat |
| `POST payments/sbp/init` | СБП разовый / bind | Init (+Receipt) → GetQr | CODE:BLACK deep link |
| `POST payments/sbp/charge` | СБП autopay | Init (+Receipt) → ChargeQr(AccountToken) | Autopay |
| `POST payments/widget_init` | T-Kassa SDK | Init (+Receipt) `DATA.connection_type=Widget` | SpeedPay |
| `GET payments/status/:id` | Poll | GetState → Confirm if AUTHORIZED (**без Receipt**) | SBP return, inline |
| `POST orders/:id/finalize` | Cold start return | sync_order! / sync_for_rebill! | CODE:BLACK lifecycle |
| `POST orders/:id/cancel` | Refund | Cancel (**без Receipt**, #40) | Auto refund |

---

## Receipt contact policy (#72)

| Правило | Поведение |
|---------|-----------|
| Источник | `MobileCustomer` заказа через `Payments::TbankReceiptBuilder.for_order!` |
| Приоритет | валидный **Email** → только `Receipt.Email`; иначе **Phone** → `Receipt.Phone` |
| Без контакта / битый email | Error **до** Init (запрос в Т-Банк не уходит) |
| Confirm | **не** передаёт Receipt (чек уже с Init) |
| Полный Cancel | **не** передаёт Receipt (#40) — касса по исходному платежу |
| Partial Cancel + Receipt | вне slice / нет API в продукте |
| SendClosingReceipt | **N/A** — в Receipt только `PaymentMethod=full_payment`; prepayment/advance нет |

Собственный mailer чека (`Orders::EmailService` / #71) — **отдельно** от ОФД Receipt.

---

## Decision tree (какой путь)

```
Checkout / repeat
│
├─ Saved RebillId + inline UX     → one_click + GET payments/status (poll)
├─ T-Kassa SDK one-click          → widget_init (amount только из БД)
├─ New PAN + toggle save_card     → GET card_config + new_card
├─ СБП 2-tap                      → sbp/init → redirect qr.nspk.ru → poll status
└─ СБП bound account              → sbp/charge

Card declined (119/1051) in widget flow → fallback: sbp/init OR new_card (orderId сохранён).
```

---

## External endpoints

- `POST /callbacks/tbank` — статусы, RebillId, RequestKey (СБП bind)
- `GET /payment/success|fail` — return URL (`TBANK_RETURN_URL`)

Init/charge из PWA — **только** через shop API выше (не прямой вызов с фронта).

---

## Mapping

| Внешний | Наш | Где |
|---------|-----|-----|
| `OrderId` | `orders.id` | `TbankCallbackJob` → Payment |
| `PaymentId` | `payments.provider_payment_id` | upsert статуса |
| `CustomerKey` | `mobile_customers.id` | recurrent / one-click / SBP |
| `RebillId` | `mobile_payment_methods.card_token` | `SavedCardStore` |
| `RequestKey` | SBP bind flow | `SbpAccountTokenFromWebhook` → AccountToken |
| `AccountToken` | SBP saved account | `MobilePaymentMethod` sbp type |

---

## Статусы (`TBANK_STATUS_MAP`)

`CONFIRMED`→succeeded · `AUTHORIZED`→processing · `REJECTED|REVERSED|CANCELED`→failed · `REFUNDED`→refunded · `PARTIAL_REFUNDED`→partially_refunded

Terminal-статус **не даунгрейдится** устаревшим webhook (`PaymentStatusUpdater`).

---

## Идемпотентность & async

- Idem: `tbank:callback:{PaymentId}:{Status}` · TTL 24h
- Подпись: `TbankAdapter.verify_notification` (SHA256 Token+Password)
- Fly: `perform_now` в контроллере, `perform_later` fallback (worker часто stopped)
- Circuit breaker: `tbank:cb:*` (5 fail → open 60s)

---

## ENV

`TBANK_TERMINAL_KEY` · `TBANK_PASSWORD` · `TBANK_RETURN_URL`

NotificationURL в кабинете → `https://<fly-host>/callbacks/tbank`

### Fiscalization (#73)

Тот же `POST /callbacks/tbank`. Детект: `Status=RECEIPT` (или `NotificationType=NotificationFiscalization`).

| Поле | Использование |
|------|----------------|
| `Url` | ссылка на чек в ЛК |
| `FnNumber` / `FiscalDocumentNumber` / `FiscalDocumentAttribute` | ФН/ФД/ФП + idempotency |
| `Type` | признак расчёта → `payment` / `refund` |
| raw | `fiscal_receipts.receipt_data.raw` |

Ответ на **любое** успешное уведомление (платёж и fiscal): HTTP 200 + тело **`OK`** (plain text, без JSON). Иначе банк ретраит (час → сутки → архив). Ошибки (невалидный Token и т.п.) — по-прежнему 4xx/5xx JSON.

Схема/пример: `docs/operations/milestones/veha_2/artifacts/fiscal_receipts_personal_cabinet/`.

---

## Риски

| Риск | Куда |
|------|------|
| Webhook без RebillId + save_card | `TbankPaymentSync#sync_for_rebill!` |
| Duplicate webhook | plain `OK` (idempotency claim; без `duplicate: true` в теле) |
| Race webhook vs polling | тест race webhook/polling |
| save_card=false | `SavedCardStore.allowed_for?` |
| Worker stopped Fly | delayed RebillId · `artifacts/usercards_*` |
| ErrorCode 3001, 119, 1051 | кабинет/GetState — не всегда баг приложения |

---

## Проверка

```bash
bin/rails test test/controllers/callbacks/tbank_controller_test.rb
bin/rails test test/services/payments/tbank_adapter_test.rb
bin/rails test test/integration/shop/api/qa_section_2_3_payment_cart_test.rb
bin/rails test test/integration/shop/api/sbp_payment_init_test.rb
bin/rails test test/integration/shop/api/sbp_autopay_charge_test.rb
bin/rails test test/integration/shop/api/payment_widget_init_test.rb
bin/rails test test/integration/shop/shop_usercards_phase1_persist_test.rb
```

Доки Т-Банка: [SpeedPay setup](https://developer.tbank.ru/eacq/intro/developer/setup_js/setup_speedpay/) · [SBP autopay](https://developer.tbank.ru/eacq/scenarios/payments/PCI_DSS/autopay/) · [Cancel](https://developer.tbank.ru/eacq/scenarios/cancel_confirm/)

Приёмка: Fly MCP **Point A** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`.
