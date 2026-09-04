# Bridge: PWA real-time (статусы, push, cascade)

Источник правды смены статуса заказа — **табло бариста**, не shop API.

---

## Upstream (barista → PWA)

| Триггер | Путь | Сервис |
|---------|------|--------|
| Смена статуса | `PATCH /barista/orders/:id/update_status` | `Barista::OrderStatusUpdateService` |
| Отмена с табло | barista cancel flow | `Barista::OrderCancellationService` |

После commit в БД → **`Shop::GuestOrderBroadcaster.call(order:, old_status:)`** (только `order.source == "mobile"`).

---

## GuestOrderBroadcaster (цепочка)

```
Barista update_status
  → GuestOrderBroadcaster
       1. GuestOrderChannel.broadcast_to (ActionCable)
       2. OrderStatusPushNotifier (FCM)
       3. AppleWallet::PassUpdater (если pass exists)
       4. OrderReadyCascadeJob.perform_later (если status == ready)
```

**Cable payload:** `type`, `order_id`, `status`, `can_cancel`, `payment_settled`, `old_status`, `order_number` (+ cancel meta).

**Soft-fail:** ошибки Cable/Wallet не блокируют cascade job.

---

## ActionCable

| Компонент | Путь |
|-----------|------|
| Channel | `Shop::GuestOrderChannel` |
| FE subscribe | `app/frontend/lib/shopOrderCable.js` |
| Auth | `tenant_id`, `order_id`, `reconnect_token`; optional `customer_id` из session |

**Presence:** subscribe → `OrderReadyPresence.mark_online!` (skip SMS в cascade если online).

**Reconnect fallback:** `POST /shop/api/session/reconnect` + повтор subscribe; polling `GET orders/active` (#47).

---

## Push & Wallet

| Канал | Сервис | Endpoint регистрации |
|-------|--------|----------------------|
| FCM WebPush | `OrderStatusPushNotifier`, `OrderStatusPushPayload` | `POST /shop/api/push/register` |
| Apple Wallet | `AppleWallet::PassGenerator`, `PassUpdater` | `GET /shop/api/orders/:id/wallet_pass` |

**ready_notified_at:** `ReadyPushClaim` — атомарный claim перед первым ready-push (#35 C1). Колонка `orders.ready_notified_at`.

**FCM:** `tag: order-{id}` — замена пушей; action buttons → SW fetch cancel API.

**#77 Subscription offer CTA (ready):** point `subscription_offer_settings` (`enabled`, `second_cta_mode` tips|subscription). Shop config exposes mode; profile exposes server `eligible_for_subscription_offer`. Engagement signals (first-write-wins): `pwa_installed_at` via `POST /shop/api/pwa_install` (`appinstalled`), `push_enabled_at` via push register, `email_collected_at` via `POST orders/:id/email`. CTA machine: on `ready` + mode=subscription + eligible → second button `subscription`; else tips fallback. Absent/disabled settings → legacy CTA.

ENV: Firebase/VAPID — см. `Shop::FirebaseConfig`.

---

## Cascade «Заказ готов» (#39)

```
ready status
  → OrderReadyCascadeJob
       → OrderReadyPresence (online? skip SMS)
       → OrderReadyPaidNotifier → SMS.ru (≤70 chars)
```

Логи: `order_notification_logs`. SMS канон: **без Telegram** (superseded v1).

---

## Shop API (read path для UI)

| Endpoint | UI |
|----------|-----|
| `GET orders/active` | compact / multi sheet, accordion receipt |
| `GET orders/:id` | detail + reconnect_token |
| `GET frequent_products` | скрыть «повторить» если `has_active_order` |

**Задачи:** #35 compact sheet · #36 receipt · #38 OS-detect · #39 cascade · #40 cancel · #47 polling fallback.

---

## Edge cases

| Симптом | Проверить |
|---------|-----------|
| Статус на табло есть, PWA нет | Cable reconnect; `/orders/active` poll; worker для jobs |
| Повторы пропали после заказа | stale active в `orders/active`; abandon/finalize |
| Дубли ready SMS | `ready_notified_at` claim |
| Push не приходит | `push/register` 401; FCM env; customer push_enabled |

---

## Проверка

```bash
bin/rails test test/services/shop/guest_order_broadcaster_test.rb
bin/rails test test/services/shop/guest_order_broadcaster_sheet_contract_test.rb
bin/rails test test/jobs/shop/order_ready_cascade_job_test.rb
bin/rails test test/jobs/shop/ready_push_job_test.rb
bin/rails test test/integration/shop/api/push_register_test.rb
bin/rails test test/integration/shop/api/wallet_pass_test.rb
bin/rails test test/integration/shop/order_status_sheet_mount_acceptance_test.rb
```

Приёмка: barista ready на Point A → PWA sheet + push/wallet smoke.
