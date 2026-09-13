# todo — TASK_84 Status sheet receipt restore

| Поле | Значение |
|------|----------|
| **ID** | `TASK_84` / CBR **#84** |
| **Тип** | витрина / PWA / статусная шторка (hot-path) |
| **Приоритет** | medium |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-84-status-sheet-receipt-restore.md`](../milestones/veha_2/requirements/customer_tasks/TASK-84-status-sheet-receipt-restore.md) |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | `aoa__dismiss` / × · `orderStatusSheet.js` · реализация `receiptView` · API · Cable · gem’ы оплаты · `todo-[feature].md` |
| **EXT** | расширяет «Мульти-статусная шторка…» · reverse QA `7ab3f3e6` (status row without receipt) |

## SBR

- [x] **SPEC** — этот файл · пути + Не ломать/Проверка
- [ ] **RED** — снять/переписать тест-запрет `receiptView` (~211–223) → позитив; падает до UI
- [ ] **GREEN** — рендер чека + CTA «Состав заказа» через существующие хелперы
- [ ] **regress** — команды из «Проверка»
- [ ] **REVIEW** — local · bugbot + security · Entire · push · CI
- [ ] **deploy** — только апрув · затем Fly MCP Point A

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `app/frontend/components/ActiveOrdersAccordion.svelte` | восстановить блок чека после `meta/progress/CTA` + CTA `LABELS.receipt`; **не** трогать `aoa__dismiss` (~139–150) |
| `app/frontend/lib/orderStatusNotifyActions.js` | подключить существующий `openOrderReceipt` к CTA (без переписывания хелпера без нужды) |
| `test/javascript/active_orders_accordion_test.mjs` | участок ~211–223: убрать запрет `receiptView` / заменить позитивом |

**Использовать, не менять реализацию:**
- `app/frontend/lib/activeOrdersAccordion.js` — `receiptView` / `receiptScrollStyle` / `toggleExpandedOrder` (только import + вызов)

**Соседи (blast-radius, не менять):**
- `app/frontend/lib/orderStatusSheet.js` — dismiss/`refreshMode` (#83)
- `app/frontend/components/OrderActionButtons.svelte` — чужие CTA (cancel/chat/tips/wallet/push)
- `test/javascript/order_status_notify_actions_test.mjs` · `order_status_sheet_test.mjs` — регресс dismiss

## Не ломать

1. Dismiss × / `aoa__dismiss` (#83) — локальный hide без API.
2. `orderStatusSheet.js` (`dismissOrder` / `refreshMode` / Cable keep) — без диффа.
3. Оплата / checkout / Repeat — статусная шторка не ломает pay-path.
4. Реализация `receiptView` / Cable (`shopOrderCable.js`) — только использование чека, без переписывания хелпера и подписки.

## Проверка

```bash
node --test test/javascript/active_orders_accordion_test.mjs
node --test test/javascript/order_status_notify_actions_test.mjs test/javascript/order_status_sheet_test.mjs
```

(ТЗ упоминает `yarn test` / `yarn tsc` — в репо нет script `test`; канон зоны — `node --test` как у #83.)

После deploy (не на SPEC): Fly MCP Point A + артефакт в `artifacts/status_sheet_receipt_restore/mcp/`.

## DoD

- [ ] Тест-запрет `receiptView` (~211–223) снят или заменён позитивом
- [ ] В `ActiveOrdersAccordion.svelte` блок чека после `meta/progress/CTA` через `receiptView(order)`
- [ ] Видны: наименование, модификаторы, qty, цена, скидка, итог
- [ ] CTA «Состав заказа» (`accepted`/`paid`/`preparing`) → `openOrderReceipt` → `toggleExpandedOrder`
- [ ] Длинный чек: внутренний scroll (`receiptScrollStyle` / max-height + overflow-y auto)
- [ ] `aoa__dismiss` / `orderStatusSheet.js` не изменены
- [ ] «Проверка» PASS
