# todo — Order ready cascade WS/Push/Wallet → SMS (#39 v2)

**ТЗ:** [`customer_tasks/Каскад уведомлений Заказ готов PWA WS Push WebPush Apple Wallet SMS.md`](../milestones/veha_2/requirements/customer_tasks/Каскад%20уведомлений%20Заказ%20готов%20PWA%20WS%20Push%20WebPush%20Apple%20Wallet%20SMS.md)  
**Артефакты:** [`artifacts/order_ready_cascade_ws_push_sms/`](../milestones/veha_2/artifacts/order_ready_cascade_ws_push_sms/)  
**Фаза:** PHASE 0 `[x]` · SPEC `[x]` · RED/GREEN `[x]` · REVIEW `[x]` · MCP/deploy **`[x]` v427**  
**Supersedes:** v1 WS→TG→SMS (`order_ready_cascade_ws_telegram_sms`)

---

## PHASE 3: REVIEW (2026-08-04)

| Проверка | Результат |
|----------|-----------|
| Cascade / presence / SMS / broadcaster / channel / TG client dormant | **45 runs / 91 assertions PASS** |
| Barista OrdersController / OrderStatusUpdateService | **без diff** |
| Telegram в PaidNotifier | **удалён** |
| Presence log | `SMS skipped` (не Paid channels) |
| MCP / Fly deploy | **v427 PASS** · evidence `mcp/fly_v427_2026-08-04/` |

---

## Канон стека (маппинг ТЗ → CoffeeOS)

| В ТЗ | В репо (делать так) | Не делать |
|------|---------------------|-----------|
| RSpec / WebMock / `spec/…` | **Minitest** | Не `spec/` |
| Sidekiq | **Solid Queue** | — |
| Redis presence | **`Rails.cache`** + `OrderReadyPresence` | — |
| WebPush / VAPID | **FCM** (уже #37–38) | Не второй WebPush |
| Apple Wallet | **PassUpdater** | — |
| `notification_histories` | **`order_notification_logs`** | — |
| Telegram | **убран из cascade** | Не вызывать из PaidNotifier |

### Каскад v2

```text
ready → Broadcaster → WS + FCM + Wallet + OrderReadyCascadeJob
  → online? → "SMS skipped"
  → offline → SmsRuClient.send_message! → order_notification_logs
```

---

## Шаги

| # | Что | Статус |
|---|-----|--------|
| 1 | Бесплатные каналы + enqueue cascade | **GREEN `[x]`** (reuse) |
| 2 | Presence → `SMS skipped` | **GREEN `[x]`** |
| 3 | SMS ≤70 + fault tolerance; без TG | **GREEN `[x]`** |

### Backlog

- `codeblack.xyz/o/{hash}` deep link
- DROP `telegram_chat_id` / cleanup `TelegramBotClient` после апрува
- MCP Fly после push/deploy + SMS_RU secrets
