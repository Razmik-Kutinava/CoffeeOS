# todo — #35 Order status compact sheet + Push (SPEC 2026-08-06 · скрин 06)

**ТЗ:** [`customer_tasks/Интеграция статусной модели…`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20статусной%20модели%20в%20компактную%20шторку%20PWA%20и%20Push.md)  
**Артефакты:** [`order_status_compact_sheet_push/`](../milestones/veha_2/artifacts/order_status_compact_sheet_push/) · канон UI: `screenshots/01–06`  
**Канон шторки:** `coffeeos-cart-sheet.mdc` — одна `CartSheet`, статус = секция, не overlay  
**Baseline:** код A/B/C + Fly **v432** MCP PASS (01–05); локально **prog38** (status+cart stack)

---

## Маппинг ТЗ → CoffeeOS (не React / RSpec / Sidekiq)

| ТЗ заказчика | Канон CoffeeOS |
|---|---|
| `OrderStatusChannel` | `Shop::GuestOrderChannel` + `GuestOrderBroadcaster` + `shopOrderCable.js` |
| `after_update_commit` → job | **Не** model hook — вызов Broadcaster из `Barista::OrderStatusUpdateService` / payment / cancel (эквивалент post-commit) |
| `paid` в статусах виджета | Домен: `accepted` (+ `payment_settled`); API `#active` = `accepted`/`preparing` |
| RSpec `spec/…` | Rails `test/` |
| Vitest/React `OrderStatusWidget` | Svelte `OrderStatusSheet` + `node --test` (`test/javascript/order_status_sheet_test.mjs`) |
| Sidekiq | ActiveJob (GoodJob / adapter проекта) · `Shop::ReadyPushJob` |
| `pointer-events: none` на контейнере | Канон: `embedded=true` внутри CartSheet (одна fixed-плоскость). Legacy `pointer-events` только non-embedded |

---

## Baseline — уже сделано (не переоткрывать без регрессии)

| Блок | Статус | Evidence |
|---|---|---|
| **A1** Cable broadcast `{order_id,status}` | `[x]` | `GuestOrderBroadcaster` · `guest_order_channel_test` |
| **A2** Show accepted/preparing; hide `ready`; home+product; scroll >2 | `[x]` | FE filter + `#active` · Fly v432 · `order_status_sheet_*` |
| **A3** Reconnect → GET `/shop/api/orders/active` | `[x]` | `OrderStatusSheet` online/reconnect · TTL 24h (#42) |
| **B1/B2** Ready → async push «…заберите на кассе!» | `[x]` | `OrderStatusPushNotifier` → `ReadyPushJob` |
| **C1** `ready_notified_at` + atomic claim | `[x]` | DDL + `ReadyPushClaim` |
| Embedded в CartSheet (не App sibling) | `[x]` | `#44` / status-inside-sheet |
| Status + cart peek стык (не mutex) | `[x]` лок. | `prog38` · `active_order_cart_peek_stack_test` · **push/MCP ждёт апрув** |

---

## Gaps → работа (RED → GREEN)

### D — Expanded канон со скрина 06 (главный остаток)

Скрин: `screenshots/06_expanded_sheet_status_plus_cart.png` (стикер **`expanded`**, подпись «если заказ еще»).

| # | Шаг | Статус | Файлы / тесты |
|---|-----|--------|---------------|
| D0 | SPEC зафиксирован (этот todo) | `[x]` | `todo.md` · SESSION_STATE |
| D1 | **DOM-порядок в expanded/checkout:** gesture → **OrderStatusSheet** → (CTA) → **позиции корзины** → **pay/checkout** — без второго fixed/z-index | `[ ]` | `CartSheet.svelte` · тест integration: порядок `data-testid` при `MODE_EXPANDED`/`payStack` + `hasActiveOrder` |
| D2 | **Мета-строка:** на expanded (скрин 06) третий сегмент = **название позиции (только продукта)**; на home peek (скрин 01) допускается точка/локация — не ломать 01 без апрува | `[ ]` | `ActiveOrdersAccordion` / `accordionRowView` · API `#active` уже отдаёт items · тест JS/integration |
| D3 | Регрессия зоны shop + JS sheet | `[ ]` | `bin/rails test test/integration/shop/…` (точечно status/cart) · `node --test test/javascript/order_status_sheet_test.mjs` |
| D4 | MCP приёмка vs **скрин 06** (после push `prog38` + D1/D2) | `[ ]` | Fly · evidence в `artifacts/…/mcp/` · expanded: статус над линиями + оплата |
| D5 | Optional: barista → `ready` → hide + один push (PARTIAL с v432) | `[ ]` | только по апруву / вместе с D4 |

### Soft / не блокер (backlog, не в RED без go)

| # | Что | Решение SPEC |
|---|-----|--------------|
| S1 | Toast + exponential retry на API 500 (буква A3) | Сейчас: banner «Нет связи» / `error_retry` · toast **не** обязателен для exit #35 · PRACTICES если понадобится |
| S2 | Буквальный `after_update_commit` на `Order` | **Не делать** — сервисный Broadcaster = канон; риск дублей |
| S3 | Чеклист `[ ]` в customer_tasks `.md` | Не синхронить галочки в теле ТЗ заказчика; статус — CBR / этот todo |

---

## Exit Criteria (обновлённые)

1. `[x]` Виджет только во время готовки (accepted/preparing); hide на `ready` — baseline.
2. `[x]` Push ready ровно один раз (`ready_notified_at`) — baseline; live smoke D5 optional.
3. `[x]` >2 заказов → scroll — baseline (v432).
4. `[ ]` **Скрин 06:** в **expanded** шторки видны статус **над** корзиной **и** оплата; каталог/карточка кликабельны выше шторки; одна CartSheet.
5. `[ ]` Новые тесты D1/D2 зелёные + регрессия зоны.

---

## Порядок BUILD

1. **RED D1+D2** — падающие тесты порядка DOM + meta product name в expanded  
2. **GREEN** — минимальный FE/API  
3. Регрессия shop status/cart  
4. REVIEW + ops  
5. Push/MCP D4 — **только по явной просьбе**

**DDL:** не требуется (`ready_notified_at` уже есть).

**Риски:** не вернуть `hideCartTail`; не вынести статус в fixed overlay; не ломать #41 CTA / #44 product CTA.
