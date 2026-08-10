# Bridge: уведомления, push, real-time, legacy callbacks

Real-time chain: [`pwa-realtime.md`](pwa-realtime.md). Shop endpoints: [`shop-api.md`](shop-api.md) § Push.

---

## WebSocket + broadcast

| Роль | Путь |
|------|------|
| Broadcaster | `Shop::GuestOrderBroadcaster` |
| Channel | `Shop::GuestOrderChannel` |
| Presence | `OrderReadyPresence` (online → skip SMS) |
| Barista trigger | `PATCH /barista/orders/:id/update_status` |

Payload: `status_changed`, `can_cancel`, `payment_settled`, `order_number`.

---

## FCM WebPush

| Роль | Путь |
|------|------|
| Register | `POST /shop/api/push/register` → `PushRegistrationService` |
| Notifier | `Shop::OrderStatusPushNotifier` |
| Payload | `OrderStatusPushPayload` (tag, actions, progress unicode) |
| SW handler | `service-worker.js` — action cancel/chat/tips |

ENV: Firebase admin + VAPID (`Shop::FirebaseConfig`). Dev: `FCM_SIMULATE=1`.

**Edge:** register требует logged-in customer (email verify). 503 если push не настроен на сервере.

---

## Apple Wallet

| Роль | Путь |
|------|------|
| Download | `GET /shop/api/orders/:id/wallet_pass` |
| Update | `Shop::AppleWallet::PassUpdater` (from broadcaster) |
| Storage | `order_wallet_passes` |

Runbook детали: `docs/operations/milestones/veha_2/runbooks/APPLE_WALLET_ORDER_PASS.md`

---

## Cascade «Заказ готов»

```
GuestOrderBroadcaster (status == ready)
  → OrderReadyCascadeJob
       → OrderReadyPresence (skip SMS if online)
       → OrderReadyPaidNotifier → SMS.ru
```

**Idempotency:** `orders.ready_notified_at` via `ReadyPushClaim` (#35).  
**Логи:** `order_notification_logs`.

Superseded: Telegram leg (v1 task) — **не использовать**.

---

## Лояльность

| | |
|---|---|
| Схема | `loyalty_accounts`, `loyalty_transactions` |
| earn/spend | **нет сервиса** в `app/services/` |
| Merge | `CustomerProfileMerger#reassign_loyalty!` |

При начислениях — отдельная задача; обновить этот файл.

---

## Legacy callbacks (не Т-Банк)

| Endpoint | Назначение |
|----------|------------|
| `POST /callbacks/payments` | `Callbacks::EventsController` |
| `POST /callbacks/fiscal_receipts` | фискальные колбэки |

ENV: `CALLBACK_*` как в проекте.

**Не путать** с `POST /callbacks/tbank` (эквайринг).

---

## Проверка

```bash
bin/rails test test/services/shop/guest_order_broadcaster_test.rb
bin/rails test test/jobs/shop/order_ready_cascade_job_test.rb
bin/rails test test/jobs/shop/ready_push_job_test.rb
bin/rails test test/integration/shop/api/push_register_test.rb
bin/rails test test/integration/shop/api/wallet_pass_test.rb
bin/rails test test/integration/b21_guest_notify_test.rb
```

Приёмка: Point A — barista ready → FCM/Wallet smoke + cascade SMS (test terminal / simulate).
