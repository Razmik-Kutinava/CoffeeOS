# todo — Order status compact sheet + Push (#35)

**ТЗ:** [`customer_tasks/Интеграция статусной модели в компактную шторку PWA и Push.md`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20статусной%20модели%20в%20компактную%20шторку%20PWA%20и%20Push.md)  
**Артефакты (канон UI):** [`artifacts/order_status_compact_sheet_push/`](../milestones/veha_2/artifacts/order_status_compact_sheet_push/)  
**Фаза:** PHASE 2: BUILD · C1/C2 GREEN `[x]` · A1–A3/B ещё RED

---

## SPEC (канон CoffeeOS)

### Бизнес-цель
Не блокировать гостя на full-screen `/order/:id`. Статус активного заказа — в **сквозной sticky-шторке** (peek/hidden) поверх каталога и карточки товара; бариста меняет статус на табло → ActionCable + Push; при «Готов» — ровно 1 пуш (идемпотентность).

### Глобальные ограничения (из ТЗ)
- Шторка **не** блокирует клики по каталогу / карточкам (`pointer-events` / z-index).
- **Не трогать** базовую схему `orders.status` и основные связи; для C1 — только `ready_notified_at` **или** `order_push_logs` (Migration Gate + `go`).
- Real-time — **только** ActionCable (штатный).
- Push / `.pkpass` / тяжёлое — **ActiveJob** (в CoffeeOS = **Solid Queue**, не Sidekiq/GoodJob). POS не блокируется.

### Что уже есть (не дублировать)

| Компонент | Путь | Роль |
|---|---|---|
| Guest WS channel | `app/channels/shop/guest_order_channel.rb` | `stream_for order`; auth reconnect_token / session |
| Broadcast из POS | `Shop::GuestOrderBroadcaster` ← `Barista::OrderStatusUpdateService` | payload `status_changed` + order_id/status (+ meta) |
| FE cable | `app/frontend/lib/shopOrderCable.js` | subscribe + retry 5s; used by OrderStatus / settle |
| 4-step progress | `app/frontend/lib/orderStatusProgress.js` | Принят→Оплачен→Готовится→Готов |
| Full-screen B1.1 | `app/frontend/routes/OrderStatus.svelte` (~577) | `/order/:id` — **оставить** как detail; не раздувать |
| Cart peek | `CartSheet.svelte` (~586) + `ProductCartPeek.svelte` | паттерн peek/hidden; **корзина**, не статус |
| Push pipeline | `OrderStatusPushNotifier` → `SendPushNotificationJob` → `FcmClient` | FCM; тексты B2.1 близки к ТЗ |
| Order FSM | `Order::VALID_TRANSITIONS` | `ready → preparing` **запрещён** |
| ActiveJob | Solid Queue (prod) | маппинг ТЗ Sidekiq/GoodJob |
| Order show API | `GET /shop/api/orders/:id` | refresh одного заказа |
| Session LS | `shopGuestSession.js` | `lastGuestOrderId` + reconnect_token |

### Gaps (делать)

1. **FE sticky widget** — новый компонент(ы) статуса в peek/hidden на Home + Product (+ App mount); канон = 5 скринов.
2. **Multi-order** — ≥2 активных полос; scroll если **>2** (подпись заказчика).
3. **Coexistence с CartSheet** — оба внизу; статус не должен ломать peek корзины / клики; layout/padding контента.
4. **A3 reconnect GET** — при `connected`/online: фоновый refresh активных заказов; 404/500 → hide/toast + backoff.
5. **API active orders** — сейчас один `lastGuestOrderId`; для multi нужна `GET …/orders/active` (или history filter) + хранение списка id.
6. **Push copy** — выровнять тексты под ТЗ («Бариста уже готовит…» / «Ваш кофе готов! Заберите на кассе») без ломки B2.1 acceptance без апрува — в GREEN уточнить в notifier.
7. **C1/C2 idempotency** — `ready_notified_at` (предпочтительно колонка на `orders`) + atomic skip duplicate ready-push; Cable всё равно шлёт.
8. **B3 Apple Wallet / pkpass / APNs** — **нет кода**; отдельный подшаг, можно отложить в backlog если scope велик (зафиксировать в REVIEW/CBR).
9. **Не создавать** параллельный `OrderStatusChannel` — маппинг на `Shop::GuestOrderChannel` (см. ниже).
10. **Не** `after_update_commit` на всей модели Order вслепую — оставить триггер в broadcaster/service (уже есть); при желании тонкие job-обёртки вокруг notifier.

### Маппинг путей (ТЗ → CoffeeOS)

| ТЗ (шаблон) | CoffeeOS |
|---|---|
| `OrderStatusChannel` | **`Shop::GuestOrderChannel`** (+ при необходимости alias/doc); payload уже шире `{order_id,status}` |
| `PreparingPushJob` / `ReadyPushJob` | Расширить `OrderStatusPushNotifier` + опц. тонкие `Shop::PreparingPushJob` / `ReadyPushJob` → тот же FCM path; **Solid Queue** |
| Web Push | **FCM** (`FcmClient` + `firebasePush.js`); VAPID stub в SW не трогать как основной путь |
| Apple Wallet `.pkpass` | **нет** — новый scope (B3-Wallet) или backlog |
| `ready_notified_at` / `order_push_logs` | DDL: предпочтительно **`orders.ready_notified_at`** (nullable timestamptz) |
| `spec/…` / Vitest/React | **не использовать** |
| Backend tests | `test/channels/shop/…`, `test/services/shop/…`, `test/services/barista/…`, `test/integration/shop/…` |
| Frontend tests | `test/javascript/order_status_sheet_*.mjs` (`node --test`) |
| Sticky widget | `app/frontend/components/OrderStatusSheet.svelte` (+ lib `orderStatusSheetStore.js` / `orderStatusActive.js`) |
| POS soft Cable fail | Сегодня broadcaster **rescue** — POS не 500 при Cable down. ТЗ хочет hard-fail — **не менять** без явного апрува (риск регресса табло); в A1 зафиксировать soft-fail как канон CoffeeOS |

### Архитектура GREEN (по блокам ТЗ)

| Шаг | Слой | Код (цель) | Тесты (RED→GREEN) |
|-----|------|------------|-------------------|
| **A1** | BE | Reuse GuestOrderChannel + GuestOrderBroadcaster; документировать контракт payload; не ломать POS soft-fail | channel + broadcaster (+ assert payload keys) |
| **A2** | FE | `OrderStatusSheet` sticky peek/hidden; mount в `App.svelte` рядом с CartSheet; reuse `orderProgressView`; z-index/`pointer-events` так, чтобы каталог кликабелен; 1–2 полосы без scroll, >2 — scroll | JS: render steps, multi>2 scroll flag, pointer-events policy |
| **A3** | FE(+BE) | On cable reconnect / `online`: GET active order(s); 404→hide+toast; 500→error+backoff | JS reconnect refresh; integration API active |
| **B1** | BE | При `preparing`/`ready` — async job (существующий или split); **не** блокировать POS | notifier enqueue tests |
| **B2** | BE | Preparing push body по ТЗ (или B2.1 + note); Solid Queue | `order_status_push_notifier_test` |
| **B3** | BE | Ready FCM; Wallet — **отдельный go/backlog** если нет сертификатов | ready job + skip Wallet stub |
| **C1** | BE+DDL | `ready_notified_at` после успешного claim перед send | migration + model/service |
| **C2** | BE | `UPDATE … WHERE ready_notified_at IS NULL` → skip push/Wallet; Cable всегда; FSM `ready→preparing` не открывать | idempotency race test |

### UI / скрины (критерий приёмки)

| Скрин | Требование |
|---|---|
| `01_home_peek_status_bar` | Главный / витрина: peek прогресс + каталог доступен |
| `02` / `03_product_*` | Карточка товара: статус внизу; add/pay не блокируются бессмысленно |
| `04` / `05_multi_*` | ≥2 статусов; scroll если **>2** |
| Подпись «если заказ еще» | **Обрыв** — трактовать как «можно заказать ещё при активном заказе» (уже в A2); уточнить у заказчика при MCP |

### Coexistence CartSheet ↔ StatusSheet (решение SPEC)

- **Вариант (канон):** StatusSheet — отдельный sticky слой над safe-area; при активных заказах занимает нижнюю полосу peek; CartSheet peek/expanded **остаётся** для корзины (как сейчас), с `padding-bottom` / stack, чтобы оба не перекрывали клики каталога вне своих hit-area.
- **Не** вшивать прогресс внутрь `CartSheet.svelte` (уже >200) — новый компонент.
- Full-screen `/order/:id` — оставить; deep-link / «детали» со шторки могут вести туда (кнопки на скринах — placeholder «кнопка с текстом» → в SPEC: primary = открыть OrderStatus / secondary = TBD, не выдумывать CTA без заказчика).

### Storage / Migration Gate

| Что | Решение |
|---|---|
| `orders.ready_notified_at` | **Да** (nullable) — проще atomic claim; **DDL только после `go`** |
| `order_push_logs` | Альтернатива; не нужна если есть колонка |
| Enum / связи `orders` | **Не трогать** |
| C2 flip-flop preparing↔ready | FSM **не** менять; идемпотентность на повторный enqueue / double ready / job retry |

### Лимиты файлов / RLS

| Файл | Сейчас | Правило |
|---|---|---|
| `CartSheet.svelte` | ~586 | **не раздувать** — статус отдельно |
| `OrderStatus.svelte` | ~577 | **не раздувать** — detail only; shared lib |
| `orderStatusProgress.js` | ~61 | reuse; иконки под скрины можно в sheet CSS |
| `App.svelte` | — | тонкий mount `<OrderStatusSheet />` |
| Tenant / RLS | — | shop API + channel как сейчас (`Current.tenant_id`, guest reconnect) |

### Риски / блокеры

| Риск | Влияние |
|---|---|
| CartSheet + StatusSheet оба sticky | Сложный layout; регрессия peek/свайпа корзины → регрессия зоны shop |
| Multi-order без API | Нужен `orders/active` или клиентский список id |
| Apple Wallet | Нет инфры/сертификатов → backlog B3-Wallet |
| Тексты push ≠ B2.1 | Менять только с пометкой в DEMO_FEEDBACK / апрувом |
| Cable hard-fail POS (ТЗ) | Конфликт с soft-rescue — **оставить soft** |
| Migration без go | Стоп на C1 |

### Открытые вопросы (не блокируют SPEC→RED A1/A2)

1. Точный текст CTA на оранжевых кнопках скринов («КУПИТЬ В 1 КЛИК» vs «кнопка с текстом»).
2. «если заказ еще» — полный смысл фразы заказчика.
3. Делать ли B3 Wallet в этом эпике или backlog.
4. Нужен ли hard-fail POS при Cable down (сейчас soft) — **по умолчанию нет**.

---

## Чеклист выполнения (SBR)

### PHASE 1: SPEC
- [x] Анализ EXISTING vs MISSING
- [x] Маппинг ТЗ → CoffeeOS
- [x] todo.md + SESSION_STATE
- [x] RED — тесты написаны (ожидаемо красные)

### PHASE 2: BUILD

#### A — Real-time виджет
- [x] A1 RED — `guest_order_broadcaster_sheet_contract_test` (нужен `order_number` в payload)
- [ ] A1 GREEN
- [x] A2 RED — `order_status_sheet_test.mjs` + mount acceptance
- [ ] A2 GREEN — OrderStatusSheet sticky peek (home+product), non-blocking
- [x] A2b RED — `shouldScrollStatusList` >2 в JS
- [ ] A2b GREEN
- [x] A3 RED — `active_orders_test` (route `orders/active`)
- [ ] A3 GREEN — reconnect GET refresh + error/toast/backoff

#### B — Push
- [x] B/C RED — `ready_push_claim_test` (ReadyPushClaim + ready_notified_at)
- [ ] B1/B2 GREEN — preparing push async (reuse notifier)
- [ ] B3 GREEN — ready FCM; Wallet = backlog unless go
- [ ] Регрессия: `order_status_push_notifier` + barista status update

#### C — Idempotency
- [x] C1 GREEN — Migration `ready_notified_at` + `Shop::ReadyPushClaim` + notifier claim/skip
- [x] C2 GREEN — atomic claim; skip duplicate push (покрыто `ready_push_claim_test`)
- [ ] A1–A3 / B GREEN — ещё RED (sheet / active / order_number)

### PHASE 3: REVIEW
- [ ] N+1/RLS/rubocop; регрессия `test/integration/shop/`
- [ ] MCP Fly vs скрины артефактов
- [ ] CHANGELOG / HANDOFF / CBR статус

---

## Команды проверки (после GREEN)

```text
bin/rails test test/channels/shop/guest_order_channel_test.rb test/services/shop/guest_order_broadcaster_test.rb test/services/shop/order_status_push_notifier_test.rb test/services/barista/order_status_update_service_test.rb
bin/rails test test/integration/shop/
node --test test/javascript/order_status_sheet_*.mjs
```

Регрессия зоны shop: `bin/rails test test/integration/shop/`
