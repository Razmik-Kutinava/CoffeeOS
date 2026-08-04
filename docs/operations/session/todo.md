# todo — Order ready cascade WS/Push/Wallet → SMS (#39 v2)

**ТЗ:** [`customer_tasks/Каскад уведомлений Заказ готов PWA WS Push WebPush Apple Wallet SMS.md`](../milestones/veha_2/requirements/customer_tasks/Каскад%20уведомлений%20Заказ%20готов%20PWA%20WS%20Push%20WebPush%20Apple%20Wallet%20SMS.md)  
**Артефакты:** [`artifacts/order_ready_cascade_ws_push_sms/`](../milestones/veha_2/artifacts/order_ready_cascade_ws_push_sms/)  
**Фаза:** PHASE 0 `[x]` · SPEC `[ ]` · RED/GREEN · REVIEW · MCP/deploy `[ ]`  
**Supersedes:** v1 WS→TG→SMS (`order_ready_cascade_ws_telegram_sms`)

---

## Канон стека (маппинг ТЗ → CoffeeOS)

| В ТЗ | В репо (делать так) | Не делать |
|------|---------------------|-----------|
| RSpec / WebMock / `spec/…` | **Minitest** `test/jobs/…`, `test/services/…` | Не заводить `spec/` |
| Sidekiq / GoodJob | **Solid Queue** (`ApplicationJob`) | Не Sidekiq |
| Redis `order:{id}:online` | **`Rails.cache`** + `Shop::OrderReadyPresence` | Не Redis ради presence |
| `in_progress` | **`preparing`** | — |
| `POST /api/v1/…/ready` | **`PATCH /barista/orders/:id/update_status?status=ready`** | Не новый endpoint |
| `OrderChannel` | **`Shop::GuestOrderChannel`** | Не ломать FE payload |
| WebPushService / VAPID | Уже: **FCM** (`ReadyPushJob` / `OrderStatusPushNotifier`) | Не второй WebPush стек без запроса |
| AppleWalletNotificationService | Уже: **`Shop::AppleWallet::PassUpdater`** | — |
| `notification_histories` | Уже: **`order_notification_logs`** | Не новая таблица |
| `SmsRuClient.send_sms` | **`Shop::SmsRuClient.send_message!`** ≤70 | Не ломать OTP |
| `SMS_RU_SENDER` | **`SMS_RU_FROM`** (+ алиас SENDер) | — |
| `codeblack.xyz/o/{order_hash}` | SMS текст: `CODE:BLACK. Заказ готов! #%{order_number}` (≤70); внешний домен — backlog | Не выдумывать order_hash DDL |
| Telegram | **Убран из каскада** | Не вызывать `TelegramBotClient` из cascade |

### Каскад (канон v2)

```text
barista PATCH update_status(ready)
  → GuestOrderBroadcaster
       → GuestOrderChannel (WS)
       → FCM ReadyPushJob + Wallet PassUpdater   # бесплатные — УЖЕ ЕСТЬ
       → OrderReadyCascadeJob.perform_later
            1) presence online? → log "SMS skipped"; return
            2) offline → SmsRuClient.send_message! → order_notification_logs
               сеть/5xx → log failed, job не падает
               ValidationError (>70) → log failed, re-raise / failed job без HTTP
```

### Секреты / ENV

| ENV | Назначение |
|-----|------------|
| `SMS_RU_API_ID` | SMS.ru |
| `SMS_RU_FROM` (≈ `SMS_RU_SENDER`) | sender |
| FCM / Wallet | уже в #37–38 (не VAPID в коде каскада) |
| `TELEGRAM_*` | **не используется** в v2 cascade (клиент может остаться dormant) |

---

## Шаги (TDD)

| # | Что | Статус |
|---|-----|--------|
| 1 | **Бесплатные каналы + enqueue** — verify Broadcaster: WS/FCM/Wallet + `OrderReadyCascadeJob` (без регрессии) | reuse GREEN v1 → **verify `[ ]`** |
| 2 | **Presence** — online → `SMS skipped` (не «Paid channels»); SmsRuClient не вызвать; cache error → re-raise | **rewrite `[ ]`** |
| 3 | **SMS ≤70 + log + fault tolerance** — offline → SMS; ValidationError до HTTP; сеть → failed в логе без crash; **без Telegram** | **rewrite `[ ]`** |

### Out of scope / backlog

- UI привязки Telegram (v1 backlog) — **снято** с этой задачи
- Внешний `codeblack.xyz/o/{hash}` deep link
- Отдельный VAPID WebPush вместо FCM
- DROP `telegram_chat_id` / удаление `TelegramBotClient` — отдельный cleanup после апрува

### Порядок

1. RED: тесты без TG + «SMS skipped»
2. GREEN: PaidNotifier → SMS-only; Cascade log message
3. Регрессия shop cascade zone
4. REVIEW + ops
