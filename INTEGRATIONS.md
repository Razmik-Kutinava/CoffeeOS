# CoffeeOS — карта интеграций (мосты)

**Живой контракт:** описываем **наш bridge** (endpoint → ключи → БД → edge cases), не официальную документацию внешних API.

**Как использовать:** `@INTEGRATIONS.md` в чате Cursor при правках оплаты / auth / OTP / уведомлений.  
**Поддержка:** тронул код из таблицы «Файлы» → обнови этот файл в том же шаге (см. `.cursorrules`).

**Стек:** Rails 8 · PostgreSQL · Svelte PWA · канон оплаты: `Payments::TbankAdapter` (без новых gem'ов).

---

## 1. Т-Банк (эквайринг, карты, СБП)

| | |
|---|---|
| **Адаптер** | `app/services/payments/tbank_adapter.rb` |
| **Webhook** | `POST /callbacks/tbank` → `Callbacks::TbankController#notify` |
| **Job** | `Payments::TbankCallbackJob` (retry ×5, queue `:critical`) |
| **Статус платежа** | `Callbacks::PaymentStatusUpdater` |
| **Карты (RebillId)** | `Payments::SavedCardStore` → `mobile_payment_methods` |
| **СБП autopay** | `Payments::SbpAccountTokenFromWebhook`, `Payments::TbankSbpAutopay` |
| **Finalize / GetState** | `Payments::TbankPaymentSync` (если webhook опоздал или без RebillId) |
| **Init из витрины** | `Shop::WidgetPaymentInitiator`, `Shop::SbpPaymentInitiator`, `Shop::NewCardPaymentService`, `Shop::OrderCreator` |

### Точки входа (наш backend)

| Endpoint | Назначение |
|----------|------------|
| `POST /callbacks/tbank` | Webhook статусов платежа, RebillId, RequestKey (СБП) |
| `GET /payment/success`, `/payment/fail` | Return URL после оплаты в браузере |
| Shop API init/charge | через сервисы выше (не прямой вызов банка из контроллера) |

### Identity & mapping

| Внешний ключ | Наш ключ | Где |
|--------------|----------|-----|
| `OrderId` (webhook/init) | `orders.id` (UUID string) | `TbankCallbackJob` ищет `Payment` по `order_id` + `PaymentId` |
| `PaymentId` | `payments.provider_payment_id` | Upsert статуса |
| `CustomerKey` | `mobile_customers.id` (UUID string) | Init recurrent / one-click / SBP |
| `RebillId` | `mobile_payment_methods.card_token` | `SavedCardStore` (idempotent по rebill или pan+exp) |
| `RequestKey` | СБП account token flow | `SbpAccountTokenFromWebhook` |

### Статусы

Т-Банк → Payment (`Payments::TbankAdapter::TBANK_STATUS_MAP`):

- `CONFIRMED` → `succeeded`
- `AUTHORIZED` → `processing`
- `REJECTED` / `REVERSED` / `CANCELED` → `failed`
- `REFUNDED` / `PARTIAL_REFUNDED` → refunded / partially_refunded

**Защита от даунгрейда:** terminal-статус (`succeeded`, `failed`, …) не откатывается устаревшим webhook (`PaymentStatusUpdater`).

### Идемпотентность & async

- Webhook: ключ `tbank:callback:{PaymentId}:{Status}` в `Payments::CacheCounter` (TTL 24h).
- Подпись: `Payments::TbankAdapter.verify_notification` (SHA256 Token + Password).
- На Fly: `perform_now` в контроллере (worker часто stopped), `perform_later` — fallback.
- Circuit breaker: SolidCache keys `tbank:cb:*` (5 failures → open 60s).

### Секреты (ENV)

| Переменная | Назначение |
|------------|------------|
| `TBANK_TERMINAL_KEY` | TerminalKey |
| `TBANK_PASSWORD` | Password для Token |
| `TBANK_RETURN_URL` | База SuccessURL/FailURL |

### Edge cases / известные риски

| Риск | Митигация / где смотреть |
|------|---------------------------|
| Webhook без RebillId при save_card | `TbankPaymentSync#sync_for_rebill!`, GetState с паузой |
| Дубликат webhook | CacheCounter idempotency → `{ ok: true, duplicate: true }` |
| Race webhook vs polling | Тест `race: webhook AUTHORIZED after polling-confirm` |
| save_card=false, но CONFIRMED | `SavedCardStore.allowed_for?` — карту не пишем |
| Worker stopped на Fly | UserCards root cause: `docs/operations/milestones/veha_2/artifacts/usercards_*` |
| ErrorCode банка (3001, 119, …) | Сначала webhook/GetState/кабинет; не всегда баг приложения |

### Проверка (локально)

```bash
bin/rails test test/controllers/callbacks/tbank_controller_test.rb
bin/rails test test/services/payments/tbank_adapter_test.rb
bin/rails test test/integration/shop/shop_usercards_phase1_persist_test.rb
```

Hot-path приёмка: **Fly MCP Point A** (`tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`).

---

## 2. SMS.ru (OTP + каскад «Заказ готов»)

| | |
|---|---|
| **Клиент** | `app/services/shop/sms_ru_client.rb` |
| **OTP оркестратор** | `app/services/shop/phone_otp.rb` |
| **Каскад ready** | `Shop::OrderReadyCascadeJob` → `Shop::OrderReadyPaidNotifier` |
| **Логи SMS** | `order_notification_logs` |

### Точки входа (Shop API)

| Endpoint | Назначение |
|----------|------------|
| `POST …/phone_otp/send` | Flash call или SMS fallback |
| `POST …/phone_otp/verify` | Проверка кода |
| `GET …/phone_otp/status` | Статус сессии OTP |

Каналы: **`flash_call`** (основной) → **`sms`** (fallback, повторная отправка того же кода). Канал `messenger` **снят**.

### Identity & mapping

| Ключ | Где |
|------|-----|
| Телефон E.164 | `PhoneNormalizer.normalize!` → `mobile_otp_codes.phone`, `mobile_customers.phone` |
| OTP код | `mobile_otp_codes` (TTL 10 min, max 5 attempts) |
| Cooldown | flash_call 20s, sms 60s; Rack::Attack throttles |

### Секреты (ENV)

| Переменная | Назначение |
|------------|------------|
| `SMS_RU_API_ID` | API ключ |
| `SMS_RU_FROM` | Отправитель (SMS) |
| Dev fallback | Без ключа — тестовый код в лог (не prod) |

### Edge cases

| Риск | Поведение |
|------|-----------|
| SMS.ru недоступен | `SmsRuClient::Error` → пользователю понятная ошибка |
| Повтор send до cooldown | `PhoneOtp::Error` «Подождите N секунд» |
| Заказ ready, юзер online (WS) | SMS **не** шлём (`OrderReadyPresence`) |
| SMS > 70 символов | `ValidationError` в `send_message!` |

### Проверка

```bash
bin/rails test test/services/shop/sms_ru_client_test.rb
bin/rails test test/integration/auth/phone_otp_test.rb
```

---

## 3. Identity & слияние профиля (auth bridge)

**Проблема «одно чиним — другое ломается»** чаще всего здесь: разные `mobile_customers` на один phone/email → «потерянная» история заказов/карт.

| | |
|---|---|
| **Сервис** | `app/services/shop/customer_profile_merger.rb` |
| **OTP verify → customer** | контроллеры `shop/phone_otp`, session после verify |
| **Email verify** | `app/services/shop/email_otp.rb`, link email flow |

### Ключи связывания

| Уникальный ключ | Таблица | Правило |
|-----------------|---------|---------|
| `phone` (normalized) | `mobile_customers` | `link_phone!` → merge donor → survivor |
| `email` (normalized) | `mobile_customers` | `link_email!` → merge |
| `customer_id` | FK на заказы, карты, push, loyalty | `reassign_foreign_keys!` при merge |

### Что переносится при merge

`orders`, `mobile_payment_methods`, `mobile_sessions`, `push_notifications`, `mobile_carts`, `loyalty_accounts` (+ transactions), optional: `order_feedback`, `promo_code_usages`.

**Не ломать:** merge в транзакции с lock; donor soft-deactivate, не destroy.

### Edge cases

| Риск | Где смотреть |
|------|--------------|
| Два профиля, один телефон | `CustomerProfileMergerTest`, `profile_merge_test.rb` |
| Гость → регистрация, старые заказы | merge при verify/link |
| Тестовый OTP на профиле заказчика | **Запрещено** (Point A / DEMO_LOGINS) |

---

## 4. Лояльность / бонусы

| Статус | |
|--------|---|
| **Схема БД** | `loyalty_accounts`, `loyalty_transactions` (есть в `schema.rb`) |
| **Бизнес-логика earn/spend** | **[DRAFT]** — отдельного сервиса начисления в `app/services/` пока нет |
| **Merge** | `CustomerProfileMerger#reassign_loyalty!` |

При добавлении начислений: новый раздел здесь + триггеры (order `succeeded`? webhook?) + идемпотентность txn.

---

## 5. Push / WebSocket (статус заказа, не оплата)

| | |
|---|---|
| **WS** | `Shop::GuestOrderBroadcaster`, `Shop::GuestOrderChannel` |
| **Presence** | `Shop::OrderReadyPresence` (online → skip SMS) |
| **FCM** | payload `Shop::OrderStatusPushPayload`; simulate: `FCM_SIMULATE=1` |
| **Каскад ready** | WS/Push → delay → `OrderReadyCascadeJob` → SMS |

Не путать с Т-Банком: это **исходящие** уведомления клиенту, не платёжный webhook.

---

## 6. Legacy / generic callbacks

| Endpoint | Назначение |
|----------|------------|
| `POST /callbacks/payments` | Generic payment events (`Callbacks::EventsController`) |
| `POST /callbacks/fiscal_receipts` | Фискальные колбэки |

При правках сверяться с `CALLBACK_*` env в проекте.

---

## Шаблон новой интеграции

```markdown
## [DRAFT] Название

**Файлы:** …
**Endpoints / webhooks:** …
**Mapping keys:** внешний → наш UUID/поле
**Secrets:** ENV …
**Idempotency:** …
**Edge cases:** …
**Проверка:** bin/rails test …
```

SPEC задачи: `.cursor/tasks/TASK-NNN/spec.md` — секция «Затронутые сервисы из @INTEGRATIONS.md».

---

*Обновлено: 2026-08-09 · первичная карта из кода (не @codebase audit). Бизнес-нюансы — дополняет владелец/заказчик.*
