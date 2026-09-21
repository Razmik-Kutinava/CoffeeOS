# todo — TASK_84-RECEIPT-DISPLAY-EXT: runtime receipt display

| Поле | Значение |
|------|----------|
| **ID** | **TASK_84-RECEIPT-DISPLAY-EXT** · семья **#84** · 2026-09-21 |
| **Тип** | доп.задача (EXT) · SBR · hot-path (status sheet) |
| **Статус** | **RED** · ждёт GREEN |
| **Ветка** | `develop` |
| **ТЗ** | `customer_tasks/TASK-84-RECEIPT-DISPLAY-EXT-…ActiveOrdersAccordion.md` |
| **Google Doc** | https://docs.google.com/document/d/13Msfo8hDhUXHHB3NoKhMQvrPxQMpvlKctvFDOkr7aEI/edit |
| **GATES** | `artifacts/active_orders_receipt_display_restore/GATES.md` · G1–G4 baseline met · G5 Fly unmet |
| **Не путать** | `#94` / TASK_94 = LK history repeat (другая задача) |
| **RED** | pending commit |

## Цель

Фактическое отображение текстового `.aoa__receipt` после CTA «Состав заказа» / expand: позиции, модификаторы, qty/price, Subtotal/Discount/Total Amount. Через существующий `receiptView` + данные `GET /shop/api/orders/active`. Без rewrite `receiptView` / backend / dismiss / Cable.

## SBR

- [x] SPEC
- [x] RED — runtime DOM: expand → `.aoa__receipt` + текст позиции + Total Amount
- [ ] GREEN — `receiptPanelView` + wire ActiveOrdersAccordion
- [ ] regress (секция «Проверка»)
- [ ] REVIEW / push / CI / G5 Fly

## Файлы (ожидаемо)

1. `test/javascript/active_orders_accordion_test.mjs` — RED/GREEN: runtime regression (DOM), не только source-contract `#84`
2. `app/frontend/components/ActiveOrdersAccordion.svelte` — фактический рендер/путь раскрытия receipt (сейчас код есть; закрыть расхождение с билдом)
3. `app/frontend/lib/activeOrdersAccordion.js` — **только если** сломан expand/`activeExpandedOrderId`; **не** переписывать `receiptView`
4. `app/frontend/lib/orderStatusNotifyActions.js` — **сосед:** только если сломан `openOrderReceipt`; сигнатуру не менять

## Blast-radius (не трогать без нужды)

- `app/frontend/components/OrderStatusSheet.svelte` — не менять state/polling
- `aoa__dismiss` / push recovery / wallet CTA в том же accordion

## Не ломать

1. Status/progress mapping + polling/Cable reconnect
2. `aoa__dismiss` (×) и dismissOrder
3. `receiptView` реализация / backend `active` + ActiveOrdersPresenter
4. Push recovery / Wallet / cancel-modal / TASK_91/#94 LK

## Проверка

```bash
node --test test/javascript/active_orders_accordion_test.mjs
ruby bin/rails test test/integration/shop/api/active_orders_receipt_test.rb test/integration/shop/api/active_orders_test.rb test/integration/shop/order_status_sheet_mount_acceptance_test.rb
```

## DoD

- [ ] Subtask 1–13 Gherkin (ТЗ) — runtime receipt виден
- [ ] Позитивный #84 contract сохранён; негативный #35 не возвращать
- [ ] Local PASS (Проверка) · GATES reverify G1–G4
- [ ] REVIEW + G5 Fly Point A после deploy
