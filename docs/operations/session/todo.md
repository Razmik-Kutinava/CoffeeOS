# todo — #35 rev: статусная шторка + Push (ревизия ТЗ 2026-08-05)

**ТЗ:** [`customer_tasks/Интеграция статусной модели в компактную шторку PWA и Push.md`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20статусной%20модели%20в%20компактную%20шторку%20PWA%20и%20Push.md)  
**Артефакты / скрины:** [`artifacts/order_status_compact_sheet_push/`](../milestones/veha_2/artifacts/order_status_compact_sheet_push/)  
**Фаза:** PHASE 0 `[x]` · SPEC **`[x]`** · RED/GREEN **`[ ]`** · REVIEW **`[ ]`** · MCP **`[ ]`**

**Контекст:** первая реализация #35 (2026-07-31, Fly v414) есть. Заказчик обновил ТЗ + 5 скринов. Этот проход — **дельта** до соответствия новому канону.

---

## Что нового у заказчика (дельта vs реализация 2026-07-31)

| # | Изменение в ТЗ | Было в коде #35 | Действие в RED/GREEN |
|---|----------------|-----------------|----------------------|
| 1 | Виджет **только** `accepted` / `paid` / `preparing`; при `ready` **исчезает** | `GET orders/active` включает **`ready`**; cable `applyCableEvent` не снимает `ready` | BE: убрать `ready` из active scope · FE: drop order on `status===ready` |
| 2 | Явный фокус: **главный экран + карточка товара** (скрины 01–05) | `OrderStatusSheet` только в `CartSheet`; `isCartSheetRoute` = `/` и `/checkout` **без** `#/product/…` | Показать виджет на `#/product/:id` (reuse `OrderStatusSheet` embedded или общий mount) |
| 3 | «Заказать ещё» на карточке при активном заказе | `ProductCartPeek` — только строки корзины, **без** progress bar | На product: peek корзины + статусная полоса как на скрине 02–03 |
| 4 | Скролл при **>2** активных заказах на карточке | `shouldScrollStatusList` уже `> 2` — ок | Проверить на product route + MCP скрин 04–05 |
| 5 | Push **только на `ready`** (нет `PreparingPushJob`) | В старом ТЗ был B2 preparing — **в новом ТЗ убран** | Не добавлять preparing-push; сверить `OrderStatusPushNotifier` |
| 6 | Текст пуша: «Ваш заказ готов, заберите на кассе!» | Проверить copy в `ReadyPushJob` / FCM | Выровнять строку при расхождении |
| 7 | Оранжевые CTA справа от прогресса | Реализовано в **#41** (`OrderActionButtons`) | Не дублировать в #35; MCP сверка со скринами после hide-on-ready |
| 8 | `OrderStatusChannel` в ТЗ | В репо: **`GuestOrderChannel`** + `shopOrderCable.js` | Не плодить канал; документировать маппинг A1 |

**Не менялось / уже есть:** `ready_notified_at`, `ReadyPushJob`, `ReadyPushClaim`, reconnect `GET /orders/active`, `shouldScrollStatusList`, non-blocking `pointer-events`, Wallet stub backlog.

---

## Канон стека (маппинг ТЗ → CoffeeOS)

| В ТЗ | В репо |
|------|--------|
| `OrderStatusChannel` | `GuestOrderChannel` · `subscribeGuestOrderStatus` |
| `OrderStatusWidget` | `OrderStatusSheet.svelte` + `ActiveOrdersAccordion.svelte` |
| `paid` | `accepted` + `payment_settled: true` |
| RSpec / Vitest / React | `test/` · `test/javascript/*.mjs` · Svelte |
| Sidekiq | **Solid Queue** (`ReadyPushJob`) |
| Скрины канон | `artifacts/.../screenshots/01–05` (2026-08-05) |

---

## PHASE 1: SPEC — шаги RED/GREEN (ждут намерения «ебашь»)

### Блок A — виджет только во время готовки

- [ ] **A1** Cable: событие смены статуса → FE обновляет список (reuse `shopOrderCable.js`)
- [x] **A2a** BE: `orders#active` — только `accepted`, `preparing` (и оплаченный accepted); **без `ready`**
- [x] **A2b** FE: при cable `status=ready` — **удалить** заказ из sheet (не показывать «Готов» в sticky)
- [ ] **A2c** Главный экран: виджет как на скрине `01` (внутри `CartSheet` / peek)
- [x] **A2d** Карточка товара `#/product/:id`: виджет + «добавить/оплатить» как скрины `02–03`
- [ ] **A2e** Multi-order scroll `>2` на home и product (`04–05`)
- [ ] **A3** Reconnect: после WS — `GET /orders/active` без ready; toast/hide по `mapReconnectError`

### Блок B — Push только ready

- [x] **B1** Hook → `ReadyPushJob` на переход в `ready` (уже есть — регрессия)
- [x] **B2** Copy пуша «Ваш заказ готов, заберите на кассе!» + Wallet fallback

### Блок C — idempotency

- [x] **C1** `ready_notified_at` claim (уже есть — регрессия + тест на race)

### Тесты (RED → GREEN)

| Зона | Файлы |
|------|--------|
| BE active scope | `test/integration/shop/api/active_orders_test.rb` |
| FE hide on ready | `test/javascript/order_status_sheet_test.mjs` |
| FE product mount | `test/javascript/order_status_product_route_test.mjs` (новый) |
| Ready push copy | `test/jobs/shop/ready_push_job_test.rb` |

### MCP приёмка (после GREEN)

- [ ] Home — скрин `01`
- [ ] Product — `02`, `03`
- [ ] Product multi — `04` или `05`
- [ ] Бариста → `ready` → виджет исчез + push (smoke)

### Риски

- Много «зависших» active на Point A — для MCP взять свежий заказ или почистить демо-данные
- `#41` CTA — не ломать при правках layout
- `OrderStatusSheet` embedded в `CartSheet` — product route может потребовать `isCartSheetRoute` расширить или второй mount

---

## Архив: #41 Order action buttons (закрыта 2026-08-05)

См. историю в git / `HANDOFF.md` · Fly v429 MCP PASS.
