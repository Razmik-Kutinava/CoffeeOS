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
- [x] **RED** — failing-тесты под 3 бага QA (`785fa2e3`)
- [x] **GREEN** — PaymentResult → `/`; status без receipt; cancel hint 1–3д; X=Скрыть (`7ab3f3e6`)
- [ ] **/regress** — команды из «Проверка»
- [ ] **REVIEW** — bugbot + security-review + Entire + push

## Баги заказчика → решения SPEC

| # | QA | Решение |
|---|-----|---------|
| 1 | После оплаты с гл. экрана — full-screen `/order/:id`; «повторить» — compact sheet | `PaymentResult` после ok → каталог (`/`). Deep-link `/order/:id` для push/offline. |
| 2a | Непонятен крестик | `aria-label="Скрыть статус заказа"` · dismissOrder |
| 2b | В статусной модели виден состав | Убран receipt/chevron из `ActiveOrdersAccordion` |
| 2c | Отмена: банк 1–3 дня | CTA hint `Вернем 100% · 1–3 дня` |
| 3 | UX по референсам | peek/multi без новой архитектуры |

## Файлы (ожидаемо)

1. `app/frontend/routes/PaymentResult.svelte` — post-pay → `/`
2. `app/frontend/components/ActiveOrdersAccordion.svelte` — без receipt; dismiss = Скрыть
3. `app/frontend/lib/orderStatusCtaMachine.js` — hint 1–3 дня
4. `app/frontend/lib/activeOrdersAccordion.js` — receiptView остаётся в lib (#36 unit); UI не зовёт
5. `test/javascript/order_action_buttons_cancel_test.mjs`
6. `test/javascript/active_orders_accordion_test.mjs`
7. `test/integration/shop/order_status_acceptance_cbr_test.rb` — `b11_02`

### Blast-radius (только читать)

8. `app/frontend/lib/orderStatusSheet.js`
9. `app/frontend/components/CartSheet.svelte`
10. `app/frontend/routes/Checkout.svelte`

## Не ломать

- Оплата / finalize / webhook idempotency
- «Повторить» one-click → compact sheet
- Табло + GuestOrderChannel / hide on ready + `ready_notified_at`
- Peek/hidden/expanded + клики каталога

## Проверка

- `node --test test/javascript/order_action_buttons_cancel_test.mjs test/javascript/active_orders_accordion_test.mjs test/javascript/order_status_sheet_test.mjs test/javascript/order_status_notify_actions_test.mjs`
- `bundle exec rails test test/integration/shop/order_status_acceptance_cbr_test.rb test/integration/shop/order_status_sheet_mount_acceptance_test.rb`
