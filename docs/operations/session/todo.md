# todo — Order action buttons status panel (#41)

**ТЗ:** [`customer_tasks/Динамический блок действий Action Buttons в статусной панели заказа.md`](../milestones/veha_2/requirements/customer_tasks/Динамический%20блок%20действий%20Action%20Buttons%20в%20статусной%20панели%20заказа.md)  
**Артефакты:** [`artifacts/order_action_buttons_status_panel/`](../milestones/veha_2/artifacts/order_action_buttons_status_panel/)  
**Фаза:** PHASE 0 `[x]` · SPEC **`[x]`** · RED/GREEN 1–7 `[ ]` · REVIEW `[ ]` · MCP/deploy `[ ]`  
**CBR:** #41

---

## Канон стека (маппинг ТЗ → CoffeeOS)

| В ТЗ | В репо (делать так) | Не делать |
|------|---------------------|-----------|
| Jest + RTL + React / `OrderActionButtons.tsx` | **Svelte** + `test/javascript/*.mjs` (node:test) | Не React / не `pwa/src/` / не внедрять TS |
| `SupportChatAdapter.test.ts` | `test/javascript/support_chat_adapter_test.mjs` | — |
| `TipsAdapter.test.ts` | `test/javascript/tips_adapter_test.mjs` | — |
| `orderButtonMapper.test.ts` | расширить `test/javascript/order_status_cta_machine_test.mjs` | Не дублировать второй mapper |
| `OrderActionButtons.test.tsx` | `test/javascript/order_action_buttons_test.mjs` (+ wiring accordion) | — |
| `tsc --noEmit` / запрет `any` | **JSDoc** typedefs; без нетипизированных «any» | Не добавлять TS ради ТЗ |
| `appConfig.chatUrl` / `tipsUrl` | `app/frontend/lib/shopAppConfig.js` (meta / `window.__COFFEEOS_SHOP__`) | Не хардкодить URL в компоненте |
| Мутация стейта из кнопок | handlers → `dispatch`/callbacks родителя (`onCancel`, `onStatusPatch`) | Не писать в order напрямую из CTA |

### Целевая поверхность UI (канон #41)

| Зона | Путь | Роль |
|------|------|------|
| **Правая колонка sticky-панели** | `ActiveOrdersAccordion.svelte` → `.aoa__actions` | **главная** — заменить `notifyActionsView` на матрицу #41 |
| Изолированный блок кнопок | `app/frontend/components/OrderActionButtons.svelte` (**новый**) | Рендер ≤2 оранжевых кнопок; без маппинга |
| Маппинг | `app/frontend/lib/orderStatusCtaMachine.js` | Расширить `hasPushSubscription`; labels по матрице |
| Full-page `/order/:id` | `OrderStatus.svelte` | Переиспользовать ту же `orderStatusCtas` (не ломать #40); не раздувать файл (754) |

### Есть в репо (не изобретать)

| Артефакт | Путь | Статус vs #41 |
|----------|------|---------------|
| Progress 4 этапа | `orderStatusProgress.js` + UI accordion/OrderStatus | **не трогать структуру** |
| CTA machine | `orderStatusCtaMachine.js` | есть accepted/cancel/chat/tips/wallet/push — **нет** `hasPushSubscription`, нет ветки `paid`, labels ≠ ТЗ |
| OS detect | `deviceDetect.js` → `getDeviceOS()` | `isIOS` = `os === "ios"` |
| Push/Wallet actions | `orderStatusNotifyActions.js` | `subscribeOrderPush` / `downloadWalletPass` |
| Cancel modal/flow | `OrderCancelModal.svelte` + `orderCancelFlow.js` | готово на OrderStatus; **нет** в accordion |
| Cable | `shopOrderCable.js` + `OrderStatusSheet` | обновляет status/progress; CTA accordion **не** status-aware |
| Cancel API | `POST /shop/api/orders/:id/cancel` | BE #40 готов |

### Глобальные ограничения (канон)

- Не менять структуру progress bar (4 этапа Принят→Оплачен→Готовится→Готов).
- Цвета панели: фон `#1a1a1a` (уже `--bg`/receipt); completed `#4caf50` (не трогать); **CTA accent для блока действий = `#ff6b35`** по макету #41 (сейчас `#ff8c42` в `CTA_STYLE` — для `OrderActionButtons` ввести отдельный `ACTION_CTA_STYLE` / override, **не ломать** тесты #37 на `#ff8c42` без апдейта).
- Не мутировать order state из кнопок — только callbacks.
- URL чата/чаевых — только из config; fallback console log по ТЗ.
- Progress bar / sheet layout — без структурных перестроек.

### Отклонения / конфликты (зафиксировано)

| ТЗ буквально | Канон репо / решение SPEC |
|--------------|---------------------------|
| React + TS + Jest | Svelte + JSDoc + node:test |
| `paid` status | В домене CoffeeOS после оплаты обычно **`accepted`**; `paid` в mapper = алиас `accepted` |
| Labels: «Включить Push» / «Добавить в Wallet» / «Чат с поддержкой» / «Оставить чаевые» | Сейчас: «🔔 Уведомление…» / «Карта в Apple Wallet» / «Написать в поддержку» / «Чаевые». **Шаг 3:** выровнять labels под #41 (kind без смены). |
| Edge: `!hasPushSubscription` → btn2 Push/Wallet **до ready включительно** | Сейчас preparing/ready android = chat+tips всегда. **Шаг 3:** edge перекрывает tips, пока нет подписки; на `ready` при `hasPushSubscription===true` — tips; при `false` — Push/Wallet (по ТЗ edge). |
| #40 preparing → «Написать в поддержку» | Label → «Чат с поддержкой» (#41); kind `chat` |
| Accordion secondary «Состав заказа» | Матрица #41 = max 2 CTA; **receipt** остаётся через expand строки аккордеона (не третья кнопка) |
| Touch target 44px | Сейчас `CTA_STYLE.heightPx: 36` — для `OrderActionButtons` **min-height 44px** (шаг 7) |

### Размер файлов

| Файл | Строк | План |
|------|-------|------|
| `ActiveOrdersAccordion.svelte` | ~309 | Тонкая замена `.aoa__actions` → `<OrderActionButtons />`; cancel modal mount рядом |
| `OrderStatus.svelte` | **754** | Не раздувать: только sync labels/machine API; handlers уже есть |
| `orderStatusCtaMachine.js` | ~67 | Расширить opts + labels; держать ≤120 |
| `OrderActionButtons.svelte` | **новый** | ≤120; только render + click → callbacks |

---

## Happy path (целевой)

```text
Sticky panel (CartSheet → OrderStatusSheet → ActiveOrdersAccordion)
  RIGHT: OrderActionButtons ← orderStatusCtas({ status, os, canCancel, hasPushSubscription })
  Cable status_changed → parent patches order.status → $derived ctas без reload
accepted/paid + !push: [Отменить заказ] [Push|Wallet]
preparing + push: [Чат с поддержкой] [Оставить чаевые]
preparing + !push: [Чат с поддержкой] [Push|Wallet]
ready + push: [Чат с поддержкой] [Оставить чаевые]
ready + !push: [Чат с поддержкой] [Push|Wallet]   # edge #41
Cancel confirm → POST /orders/:id/cancel → 200 cancelled / 4xx-5xx toast, buttons stay
Chat/Tips → openSupportChat / openTipsService (URL или console pending)
```

---

## Шаги TDD (1–7)

### Шаг 1 — SupportChatAdapter `[x]` · GREEN

- **RED:** `test/javascript/support_chat_adapter_test.mjs` — намеренный fail `ERR_MODULE_NOT_FOUND` (`supportChatAdapter.js`)
- **GREEN:** `app/frontend/lib/supportChatAdapter.js` — `openSupportChat(orderId, chatUrl?)`
  - URL → `window.open(url, "_blank")`
  - нет URL → `console.info("[Chat Integration Pending] Order: …")` (injectable `log`)
- Config read: `shopAppConfig().chatUrl` (опц. в шаге 1 — param `chatUrl` достаточно)
- Тест: `node --test test/javascript/support_chat_adapter_test.mjs` → **3/3 PASS**

### Шаг 2 — TipsAdapter (нетмонет) `[x]` · GREEN

- **RED:** `test/javascript/tips_adapter_test.mjs` — намеренный fail `ERR_MODULE_NOT_FOUND` (`tipsAdapter.js`)
- **GREEN:** `app/frontend/lib/tipsAdapter.js` — `openTipsService(orderId, tenantId, tipsUrl?)`
  - URL → `window.open`; иначе log `[Tips Integration Pending] Order: …`
- Тест: `node --test test/javascript/tips_adapter_test.mjs` → **3/3 PASS** (+ chat 3/3 регрессия)

### Шаг 3 — ButtonMapper (`orderStatusCtas`) `[x]` · GREEN

- **RED:** `order_status_cta_machine_test.mjs` — матрица #41 + `hasPushSubscription` + `paid` ≡ `accepted` + labels; **10 fail / 6 pass** (намеренно)
- **GREEN:** `orderStatusCtaMachine.js`
  - max 2; labels #41
  - edge `!hasPushSubscription` → btn2 notify (push/wallet) до ready включительно
  - `paid` ≡ `accepted` для матрицы
- Тест: CTA machine + adapters + cancel flow → **PASS** (cta 16 + adapters 6 + cancel 9)

### Шаг 4 — Статический рендер `OrderActionButtons` `[x]` · GREEN

- **RED:** `order_action_buttons_test.mjs` — ACTION_CTA_STYLE `#ff6b35` + markup/wire; **FAIL** `ERR_MODULE_NOT_FOUND` `orderActionButtons.js` (намеренно)
- **GREEN:** `orderActionButtons.js` + `OrderActionButtons.svelte` + `ActiveOrdersAccordion` (RIGHT → OrderActionButtons; чек через chevron)
- Тест зона: order_action + cta + notify + wallet + push + accordion + adapters → **57/57 PASS**
- Не трогали progress bar DOM

### Шаг 5 — Реактивность ActionCable `[x]` · GREEN

- **RED:** `order_action_buttons_cable_test.mjs` — paid→preparing CTA swap + `can_cancel` patch; **2 fail / 4 pass** (намеренно)
- **GREEN:** `orderStatusSheet.applyCableEvent` мержит `can_cancel`; accordion `$derived` status → OrderActionButtons
- Тест: cable + sheet + order_action → **25/25 PASS**

### Шаг 6 — Cancel flow в sticky-панели `[x]` · GREEN

- **RED:** `order_action_buttons_cancel_test.mjs` — Confirm Sheet + `applyStickyCancelSuccess` + sheet wiring
- **GREEN:** `stickyOrderCancel.js` + `OrderCancelModal` в `OrderStatusSheet`; `shouldShowAcceptedCancelModal('paid')`; API cancel + toast
- Тест: cancel sticky + #40 cancel flow + cable/action → **27/27 PASS**
- BE не меняли

### Шаг 7 — Mobile touch targets `[ ]` · RED `in_progress`

- **RED:** `order_action_buttons_mobile_test.mjs` — `heightPx >= 44`; **1 fail / 1 pass** (сейчас 36)
- **GREEN:** `ACTION_CTA_STYLE.heightPx = 44` + CSS wrap / не overflow

---

## Регрессия зоны (после GREEN / REVIEW)

| Зона | Команда |
|------|---------|
| JS CTA / cancel / notify / accordion | `node --test test/javascript/order_status_cta_machine_test.mjs test/javascript/order_cancel_flow_test.mjs test/javascript/order_status_notify_actions_test.mjs test/javascript/active_orders_accordion_test.mjs test/javascript/support_chat_adapter_test.mjs test/javascript/tips_adapter_test.mjs test/javascript/order_action_buttons_test.mjs` |
| Shop (если трогали API) | только если менялся BE — иначе skip |
| MCP Fly | после deploy — скрины sticky CTA по матрице статусов |

---

## Exit Criteria (маппинг)

1. Новые + обновлённые JS-тесты зелёные; ветки mapper покрыты.
2. Без новых lint/TS ошибок в затронутых FE-файлах.
3. Макет: справа от progress — реальные CTA по матрице (не «кнопка с текстом»).
4. WS: смена статуса → смена кнопок без reload.
5. Cancel до `preparing` + ошибки сети.
6. Chat/Tips — адаптеры; URL из config одной строкой.
7. Mobile: touch ≥44px, без overflow.
