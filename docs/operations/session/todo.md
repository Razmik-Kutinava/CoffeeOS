# todo — Background FCM progress + Apple Wallet (#38)

**ТЗ:** [`customer_tasks/Фоновые уведомления прогресс-бар Android FCM и Apple Wallet iOS.md`](../milestones/veha_2/requirements/customer_tasks/Фоновые%20уведомления%20прогресс-бар%20Android%20FCM%20и%20Apple%20Wallet%20iOS.md)  
**Артефакты:** [`artifacts/background_notifications_fcm_apple_wallet/`](../milestones/veha_2/artifacts/background_notifications_fcm_apple_wallet/)  
**Фаза:** SPEC `[x]` · RED/GREEN шаги 1–4 `[x]` · RED/GREEN 5 `[ ]` · REVIEW `[ ]` · MCP/deploy `[ ]`

---

## Канон стека (маппинг ТЗ → CoffeeOS)

| В ТЗ | В репо (делать так) | Не делать |
|------|---------------------|-----------|
| RSpec `spec/services/shop/…` | **Minitest** `test/services/shop/…` (+ integration при API/SW) | Не заводить `spec/` |
| Vitest / Playwright paths | **Node** `test/javascript/*.mjs` (+ при необходимости MCP Fly) | Не React/Vitest/Playwright |
| `Shop::AppleWalletPassUpdater` | Существующий **`Shop::AppleWallet::PassUpdater`** (+ `ApnsClient`, `PassBuilder`) | Не дублировать top-level класс |
| Триггер статуса | Уже: `Barista::OrderStatusUpdateService` → `GuestOrderBroadcaster` | **Не менять** `Barista::OrdersController` / `OrderStatusUpdateService` |
| FCM send | `OrderStatusPushNotifier` → `PushNotification` → `SendPushNotificationJob` → `FcmClient` · ready → `ReadyPushJob` | Не слать FCM из barista |
| SW Android | `GET /firebase-messaging-sw.js` → `app/views/shop/firebase_sw/show.js.erb` | Не сырой WebPush в `app/views/pwa/service-worker.js` |
| Cancel API | `POST /shop/api/orders/:id/cancel` (`GuestOrderCancellationService`) | Не PATCH barista |
| Wallet download | Уже #37: `GET /shop/api/orders/:id/wallet_pass` | Не `/api/v1/…` |
| UI карточки | `OrderStatus.svelte` + `ActiveOrdersAccordion` / `orderStatusNotifyActions.js` · стили `#ff8c42` / существующие классы | Нет новых CSS-переменных / Tailwind-изобретений |
| Прогресс в push | Юникод 3 клетки по статусу (ниже) · визуальный бар PWA = `orderStatusProgress.js` (B1.1) | Не новый progress UI-kit |
| Chat / Tips | Deep link `#/order/:id?action=chat\|tips` на карточку; **экранов чата/чаевых в коде нет** (`tips_initiated_at` нет в `schema.rb`) | Нет миграций без Migration Gate + go; Tips = CTA + toast/placeholder до NETMONET |

### Матрица состояний (канон — из шага 5 ТЗ; отдельной таблицы в paste не было)

| `Order.status` | FCM `tag` | Unicode body prefix | FCM `actions` | PWA CTAs (макс. 2) |
|----------------|-----------|---------------------|---------------|---------------------|
| `accepted` | `order-#{id}` | `🟩⬜⬜` | `cancel` | [Отменить] · [Push / Wallet] (как #37 OS) |
| `preparing` | `order-#{id}` | `🟩🟩⬜` | `chat`, `tips` | [Чат] · [Чаевые / Wallet] |
| `ready` | `order-#{id}` | `🟩🟩🟩` | `chat`, `tips` | [Чат] · [Чаевые / Wallet]; face pass → QR (когда PKCS7) |

Ошибка payload / APNs / cancel fetch — **log + soft-fail**, broadcaster / UI не падают.

---

## Шаги (TDD)

| # | Что | Файлы (ориентир) | Тесты | Статус |
|---|-----|------------------|-------|--------|
| 1 | Обогащение FCM payload: `tag`, unicode progress, `actions` по матрице; soft-fail | `order_status_push_payload.rb` · notifier · `ready_push_job.rb` | payload + notifier + ready + pipeline | **GREEN `[x]`** |
| 2 | SW: `notificationclick` — cancel → `fetch` cancel API; chat/tips → focus + deep link; ошибка сети → local notification | `swNotificationActions.js` · `firebase_sw/show.js.erb` · `fcm_client` JSON data | `sw_notification_actions_test.mjs` 11/11 | **GREEN `[x]`** |
| 3 | `.pkpass` enrich: face / QR / back chat+tips / strip progress | `pass_builder.rb` · runbook | pass_builder + wallet_pass + ready | **GREEN `[x]`** |
| 4 | APNs update на смене статуса если pass есть; soft-fail; ReadyPushJob без double update | `guest_order_broadcaster.rb` · `ready_push_job.rb` | broadcaster + ready + notifier + pass_builder | **GREEN `[x]`** |
| 5 | PWA UI state machine на карточке: CTAs по матрице; WS reconnect banner (B1.1 уже есть — проверить/дотянуть); max 2 кнопки; только существующие стили | `OrderStatus.svelte` · `orderStatusNotifyActions.js` / новый `orderStatusCtaMachine.js` · accordion при необходимости | `test/javascript/order_status_cta_machine_test.mjs` (+ существующие progress/cable) | `[ ]` |

### Порядок

1 → 2 (FCM+SW Android) · 3 → 4 (Wallet) · 5 (PWA).  
Каждый шаг: **RED** → commit `[RED]` → **GREEN** → commit `[GREEN]` · регрессия зоны push/wallet/shop.

### Регрессия зоны (после GREEN)

```text
bin/rails test test/services/shop/order_status_push_notifier_test.rb test/services/shop/guest_order_broadcaster_test.rb test/jobs/shop/ready_push_job_test.rb test/integration/shop/api/wallet_pass_test.rb
# + JS: node --test test/javascript/sw_notification_actions_test.mjs test/javascript/order_status_*_test.mjs
```

### Риски / backlog

| Риск | Решение в SPEC |
|------|----------------|
| PKCS7 / prod APNs device tokens | Уже PRACTICES `V2-#35-WALLET-PROD`; simulate + stub остаются; шаг 3/4 зелёные на `WALLET_SIMULATE` |
| Chat / Tips нет продукта | Deep link + CTA; Tips без DDL; NETMONET — backlog PRACTICES если не успеем |
| Двойной Wallet update на `ready` | Broadcaster: PassUpdater только если pass exists; ReadyPushJob: оставить claim+FCM, Wallet — один путь (уточнить на GREEN: либо job, либо broadcaster, не оба hard) |
| Accordion >200 строк | Логика CTAs в `lib/`, не раздувать `.svelte` |
| Race accepted→preparing→ready | Тест порядка payload / revision bump; tag дедуп на клиенте |

### Запреты (из ТЗ)

- Diff `app/controllers/barista/orders_controller.rb` · `app/services/barista/order_status_update_service.rb` = **пустой**
- Новые CSS variables / кастомные анимации / «изобретённый» Tailwind
- Смена источника правды статуса (только существующий barista PATCH → broadcaster side-effects)

---

## PHASE 1: SPEC — итог

- Интейк #38 уже в CBR / customer_tasks.
- Канон и шаги 1–5 зафиксированы здесь; **код не писали**.
- Дальше: RED шаг 1 при намерении («го / ебашь / сделай»).
