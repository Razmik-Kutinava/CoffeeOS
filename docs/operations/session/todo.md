# todo — #63 Svelte 5 status widget reactivity UX (доп к #35) DONE

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| #63 GREEN local 22/0 | done | Fly MCP Point A после push/deploy · апрув |

## Файлы (ожидаемо)
- `app/frontend/lib/orderStatusSheet.js` — иммутабельный Cable/sync, dismiss, route visibility
- `app/frontend/components/OrderStatusSheet.svelte` — X, hash visibility, visibleOrders
- `app/frontend/components/ActiveOrdersAccordion.svelte` — кнопка X
- `app/frontend/lib/stickyOrderCancel.js` — иммутабельный cancel-error patch
- `test/javascript/order_status_sheet_test.mjs` — #63 Gherkin

## Не ломать
- Guest Cable subscribe / reconnect
- Cancel CTA + modal (#41)
- Quick Repeat hide при active order (`has_active_order` API — не userDismissed)
- Cart/Checkout pay-stack

## Проверка
- `node --test test/javascript/order_status_sheet_test.mjs` → **22/0 PASS**

## SBR
- [x] PHASE 0 intake
- [x] PHASE 1 SPEC
- [x] RED/GREEN (тесты+код)
- [x] REVIEW / ops
