# todo — Order ready cascade WS→TG→SMS (#39)

**ТЗ:** [`customer_tasks/Оптимизированный каскад уведомлений Заказ готов PWA WS Push Telegram SMS.md`](../milestones/veha_2/requirements/customer_tasks/Оптимизированный%20каскад%20уведомлений%20Заказ%20готов%20PWA%20WS%20Push%20Telegram%20SMS.md)  
**Артефакты:** [`artifacts/order_ready_cascade_ws_telegram_sms/`](../milestones/veha_2/artifacts/order_ready_cascade_ws_telegram_sms/)  
**Фаза:** SPEC `[x]` · RED/GREEN 1–5 `[x]` · REVIEW `[x]` · MCP/deploy `[ ]`

---

## PHASE 3: REVIEW (2026-08-04)

| Проверка | Результат |
|----------|-----------|
| Cascade / TG / SMS / presence / channel / broadcaster | **54 runs / 126 assertions PASS** |
| Barista OrdersController / OrderStatusUpdateService | **без diff** |
| N+1 | нет циклов AR в PaidNotifier |
| RLS | `order_notification_logs` tenant policy; smoke ранее PASS |
| File size | clients/notifier/job ≤120 |
| MCP / Fly deploy | **ждут явный апрув** (+ migrate на Fly) |

---

## Канон стека (маппинг ТЗ → CoffeeOS)

| В ТЗ | В репо (делать так) | Не делать |
|------|---------------------|-----------|
| RSpec / WebMock / FactoryBot / `spec/…` | **Minitest** `test/services/…`, `test/jobs/…`, `test/channels/…` + stubs/simulate | Не заводить `spec/`, WebMock, Sidekiq |
| Sidekiq | **Solid Queue** (`ApplicationJob` / `perform_later`) | Не добавлять Sidekiq/Redis gem |
| `in_progress` | **`preparing`** | Не вводить статус `in_progress` |
| `POST /api/v1/barista/orders/:id/ready` | Уже: **`PATCH /barista/orders/:id/update_status?status=ready`** → `OrderStatusUpdateService` → `GuestOrderBroadcaster` | Не плодить `/api/v1/…/ready` |
| `OrderChannel` + payload `{order_id,status}` | **`Shop::GuestOrderChannel`** + payload `type/status_changed` (как сейчас) | Не ломать контракт Cable FE |
| `WebPushService` / `AppleWalletNotificationService` | Уже: **FCM** (`OrderStatusPushNotifier` → `ReadyPushJob`) + **`Shop::AppleWallet::PassUpdater`** | Не дублировать второй push/wallet путь |
| Redis `order:{id}:online` | **`Rails.cache`** ключ `order:{id}:online` (prod = Solid Cache; test = memory_store) | Не тащить Redis только ради presence |
| `TelegramBotClient` | Новый **`Shop::TelegramBotClient`** (отдельно от ops `TelegramAlertJob`) | Не слать гостю через `TELEGRAM_CHAT_ID` алертов |
| `telegram_chat_id` | Колонка на **`mobile_customers`** (Migration Gate) | Не на `users` (сотрудники) |
| `SmsRuClient.send_sms` произвольный текст | Расширить **`Shop::SmsRuClient`**: `send_message!(phone:, msg:)` + валидация `msg.length <= 70` | Не ломать OTP `send_sms!(code:)` |
| `SMS_RU_SENDER` | Канон ENV: **`SMS_RU_FROM`** (как OTP); алиас `SMS_RU_SENDER` опционально | Не хардкодить sender |
| `TELEGRAM_BOT_TOKEN` | Только `ENV` (уже есть у алертов) | Не логировать token |
| `NotificationHistory` | Новая таблица **`order_notification_logs`** (channel/status/error/payload) — Migration Gate | Не путать с `push_notifications` (FCM) |
| `order_hash` в ссылке | Deep link: **`/shop/#/order/{order.id}`** (короткий текст SMS); внешний `codeblack.xyz/o/…` — backlog домена | Не выдумывать `order_hash` без DDL |
| Синхронный HTTP в request | Только Job | Уже так для FCM; cascade — только Job |

### Каскад (канон поведения)

```text
barista PATCH update_status(ready)
  → GuestOrderBroadcaster
       → GuestOrderChannel (WS, soft-fail)
       → FCM / ReadyPushJob + Wallet PassUpdater   # бесплатные мгновенные — УЖЕ ЕСТЬ
       → OrderReadyCascadeJob.perform_later(order_id)  # НОВОЕ
            1) presence Rails.cache order:{id}:online?
               true  → log skip paid; return
               false → Telegram (если chat_id)
            2) TG 200 → done
               TG 400/403/5xx/timeout → SMS fallback (soft-catch, job не failed без SMS-попытки)
            3) SMS ≤70 → sms.ru; лог в order_notification_logs
```

### Presence (канон)

| Событие | Действие |
|---------|----------|
| `GuestOrderChannel#subscribed` | `Rails.cache.write("order:#{id}:online", true, expires_in: 15.minutes)` |
| `GuestOrderChannel#unsubscribed` | `Rails.cache.delete("order:#{id}:online")` |
| Cascade | `Rails.cache.read(...) == true` → skip TG/SMS |
| Cache down / raise | Job **re-raises** → ActiveJob retry; TG/SMS не вызывать |

### Секреты / ENV

| ENV | Назначение |
|-----|------------|
| `TELEGRAM_BOT_TOKEN` | Bot API для гостя |
| `SMS_RU_API_ID` | SMS.ru |
| `SMS_RU_FROM` (≈ `SMS_RU_SENDER`) | sender name |
| Simulate/test | как у OTP: без ключей → fallback/log, без реального HTTP |

---

## Migration Gate (нужен отдельный `go` перед RED шагов 3–5)

| Изменение | Rollback | Статус |
|-----------|----------|--------|
| `mobile_customers.telegram_chat_id` string nullable + index partial where not null | `remove_column` | **`[x]`** 2026-08-04 |
| `order_notification_logs` (+ RLS tenant) | `drop_table` | **`[x]`** 2026-08-04 |

Дальше: RED шаг 3 (Telegram). Chat id вставить в `mobile_customers.telegram_chat_id` вручную / console.

---

## Шаги (TDD)

| # | Что | Файлы (ориентир) | Тесты | Статус |
|---|-----|------------------|-------|--------|
| 1 | **Бесплатные каналы (verify + enqueue cascade)** — при `ready` WS/FCM/Wallet без регрессии; soft-fail Cable; enqueue `OrderReadyCascadeJob` из Broadcaster (не трогать barista controller/service) | `guest_order_broadcaster.rb` · `order_ready_cascade_job.rb` (stub) | broadcaster + ready_push + cascade enqueue | **GREEN `[x]`** |
| 2 | **Presence filter** — cache online flag в Channel; cascade skip TG/SMS если online; cache error → retry без внешних API | `guest_order_channel.rb` · cascade job | channel + `order_ready_cascade_job_test` | **GREEN `[x]`** |
| 3 | **Telegram success** — `Shop::TelegramBotClient`; текст «готов к выдаче»; 200 → log done, SMS не вызвать; 400 → clear/log chat_id → SMS | `telegram_bot_client.rb` · cascade | client + cascade | **GREEN `[x]`** |
| 4 | **Telegram fallback** — 403 / 5xx / timeout перехватить; log; один вызов SMS; job не `failed` без fallback | cascade job | cascade (timeout/403) | **GREEN `[x]`** |
| 5 | **SMS.ru ≤70 + log** — `send_message!` + ValidationError до HTTP; `order_notification_logs`; сеть → `failed` в логе, без бесконечного retry | `sms_ru_client.rb` · log model | sms_ru + cascade | **GREEN `[x]`** |

### Порядок

1 → 2 (бесплатные + presence) · **Migration Gate `go`** · 3 → 4 → 5 (TG→SMS).  
Каждый шаг: **RED** → commit `[RED]` → **GREEN** → commit `[GREEN]` · регрессия зоны.

### Регрессия зоны (после GREEN)

```text
bin/rails test test/services/shop/guest_order_broadcaster_test.rb test/jobs/shop/ready_push_job_test.rb test/jobs/shop/order_ready_cascade_job_test.rb test/services/shop/sms_ru_client_test.rb test/channels/shop/guest_order_channel_test.rb
# + при DDL: test/integration/rls_tenant_isolation_test.rb
```

### Риски / backlog

| Риск | Решение в SPEC |
|------|----------------|
| Нет Redis в стеке | Presence через `Rails.cache` / Solid Cache; семантика ключа как в ТЗ |
| Нет UI привязки Telegram | Cascade читает `telegram_chat_id`; bind-бот / deep-link — **backlog** PRACTICES/CBR |
| `codeblack.xyz/o/{hash}` | В SMS/TG пока `/shop/#/order/{id}` или короткий host из ENV; кастомный hash — backlog |
| Дубль FCM + TG | Presence: если WS online — skip paid; если offline — TG затем SMS; FCM уже ушёл бесплатно (как ТЗ) |
| Barista hot-path | **Не менять** `OrdersController` / `OrderStatusUpdateService` — только Broadcaster side-effect |
| SMS OTP контракт | Новый метод `send_message!`; `send_sms!(code:)` не ломать |
| `NotificationHistory` vs push | Отдельная таблица логов каскада, не смешивать с FCM `push_notifications` |
| File size | Client/job ≤120 строк; не раздувать Broadcaster |

### Запреты (из ТЗ + канон)

- Хардкод `TELEGRAM_BOT_TOKEN` / `SMS_RU_*`
- Синхронный HTTP Telegram/SMS в request thread
- Breaking Cable payload без FE compat
- Новый barista ready endpoint
- Sidekiq / Redis gem «заодно»
- Миграции без Migration Gate + `go`

---

## PHASE 1: SPEC — итог

- Интейк #39 уже в CBR / customer_tasks (`9edc2bbd`).
- Канон и шаги 1–5 зафиксированы здесь; **код не писали**.
- Шаг 1 ТЗ ≈ уже закрыт инфраструктурой (#35–#38); в коде — только enqueue cascade + verify.
- Дальше: RED шаг 1 при намерении («го / ебашь / сделай»). DDL TG/SMS log — отдельный `go`.
