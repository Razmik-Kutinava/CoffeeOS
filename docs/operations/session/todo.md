# todo — #35 reopen: QA правки статусной шторки PWA

| Поле | Значение |
|------|----------|
| **CBR** | #35 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Интеграция%20статусной%20модели%20в%20компактную%20шторку%20PWA%20и%20Push.md) |
| **Тип** | Fix / hot-path статусы + шторка + post-pay routing |
| **Цель** | Добить #35 по QA заказчика: единый compact-sheet после оплаты с гл. экрана; статусная модель без состава заказа; крестик = скрыть; hint отмены «1–3 дня»; UX по референсам |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Fly** | после GREEN / REVIEW — MCP (не Local-only) |
| **Ветка** | `develop` |
| **Артефакты QA** | [`…/order_status_compact_sheet_push/screenshots/qa_2026-09-06/`](../milestones/veha_2/artifacts/order_status_compact_sheet_push/screenshots/qa_2026-09-06/) |
| **Запрет** | новая параллельная фича / новый `OrderStatusChannel`; ломать `orders` schema; gem’ы оплаты; матрица CTA #41 без апрува |

## SBR

- [x] **SPEC** — пути + Не ломать + Проверка + решения
- [ ] **RED** — failing-тесты под 3 бага QA
- [ ] **GREEN** — правки в существующих файлах #35
- [ ] **/regress** — команды из «Проверка»
- [ ] **REVIEW** — bugbot + security-review + Entire + push

## Баги заказчика → решения SPEC

| # | QA | Решение |
|---|-----|---------|
| 1 | После оплаты с гл. экрана — full-screen `/order/:id`; «повторить» — compact sheet | `PaymentResult` после ok → каталог (`/` / shop home), **не** `push(/order/:id)`. Compact `OrderStatusSheet` в CartSheet ловит active через poll/cable. Deep-link `/order/:id` оставить для push/share. |
| 2a | Непонятен крестик | Уже `dismissOrder` (скрыть виджет). Уточнить `aria-label` / видимый смысл «Скрыть» — **не** отмена заказа. |
| 2b | В статусной модели виден состав (qty/удалить) | Убрать receipt / line-items из статусной строки (`ActiveOrdersAccordion`): только степпер + мета + CTA. Состав — не в status-model. |
| 2c | Отмена: банк 1–3 дня | CTA hint в `orderStatusCtaMachine` (сейчас только «Вернем 100%»); modal/toast уже имеют 1–3 дня — синхронизировать hint на кнопке. |
| 3 | UX по референсам | После #1–2 сверить peek home/product + multi>2 scroll; без новой архитектуры. |

## Файлы (ожидаемо)

1. `app/frontend/routes/PaymentResult.svelte` — post-pay redirect без full-screen OrderStatus
2. `app/frontend/components/ActiveOrdersAccordion.svelte` — без receipt/line-items; ясный dismiss (X)
3. `app/frontend/lib/orderStatusCtaMachine.js` — hint отмены с «1–3 дня»
4. `app/frontend/lib/activeOrdersAccordion.js` — view без состава в status-model (если логика не только в Svelte)
5. `test/javascript/order_action_buttons_cancel_test.mjs` — RED/GREEN hint 1–3 дня
6. `test/javascript/active_orders_accordion_test.mjs` — RED/GREEN: нет line-items в status row
7. `test/integration/shop/order_status_acceptance_cbr_test.rb` — обновить `b11_02` (больше не требует `/order/:id` после PaymentResult)

### Blast-radius (только читать)

8. `app/frontend/lib/orderStatusSheet.js` — show/dismiss/scroll>2 / pointer-events
9. `app/frontend/components/CartSheet.svelte` — embedded mount OrderStatusSheet
10. `app/frontend/routes/Checkout.svelte` — вход в payment-result (не менять без нужды)

## Не ломать

- Оплата / finalize / webhook idempotency (Tbank callback)
- «Повторить» one-click + frequentRepeat → compact sheet
- Табло бариста + `GuestOrderChannel` / hide on `ready` + Push idempotency `ready_notified_at`
- Peek/hidden/expanded CartSheet + клики по каталогу (`pointer-events`)

## Проверка

- `node --test test/javascript/order_action_buttons_cancel_test.mjs test/javascript/active_orders_accordion_test.mjs test/javascript/order_status_sheet_test.mjs`
- `bin/rails test test/integration/shop/order_status_acceptance_cbr_test.rb test/integration/shop/order_status_sheet_mount_acceptance_test.rb`
