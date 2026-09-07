# todo — #82 Cascade SMS ready + status sheet stuck

| Поле | Значение |
|------|----------|
| **CBR** | #82 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Каскад%20SMS%20после%20Заказ%20готов%20и%20шторка%20статуса%20на%20главном.md) |
| **Тип** | Fix / hot-path витрина · статусы + уведомления |
| **Цель** | После «готов» на табло: шторка статуса исчезает с гл. экрана; офлайн-гость получает SMS.ru (каскад #39) |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **Артефакты** | [`…/order_ready_cascade_sms_status_sheet_fix/`](../milestones/veha_2/artifacts/order_ready_cascade_sms_status_sheet_fix/) |

## SBR

- [x] **SPEC** (`25c1a3ce`)
- [x] **RED** (`c30478ad`)
- [x] **GREEN** (`8cae376d`)
- [x] **/regress** — JS 29/0 · rails 35/0
- [ ] **REVIEW**

## Решение (slice)

| # | Решение |
|---|---------|
| 1 | **Шторка:** `ready` = terminal; Cable снимает карточку; `/orders/active` без `ready`. |
| 2 | `onTerminal` → frequent/повторить; reconnect фильтрует terminal. |
| 3 | **SMS:** на ready `mark_offline!` перед enqueue cascade (stale presence). |
| 4 | Триггер = `PATCH update_status` → `ready`. |
| 5 | **Вне slice:** SMS URL-шаблон; Wallet/WebPush greenfield. |

## Файлы (ожидаемо)

- `app/frontend/lib/orderStatusSheet.js`
- `app/controllers/shop/api/orders_controller.rb`
- `app/jobs/shop/order_ready_cascade_job.rb`
- `app/channels/shop/guest_order_channel.rb`
- `app/services/shop/order_ready_paid_notifier.rb`
- `app/services/shop/guest_order_broadcaster.rb`

### Blast-radius (+3)

- `app/frontend/components/OrderStatusSheet.svelte`
- `app/services/shop/order_ready_presence.rb`
- `app/services/shop/sms_ru_client.rb`

## Не ломать

- Оплата One-Click / СБП / webhook → `accepted`
- «Повторить» / frequent после выдачи
- Табло баристы `update_status` + board broadcast
- Peek CartSheet на `accepted`/`preparing`

## Проверка

- `node --test test/javascript/order_status_sheet_test.mjs test/javascript/order_status_active_poll_test.mjs`
- `bin/rails test test/jobs/shop/order_ready_cascade_job_test.rb test/services/shop/order_ready_paid_notifier_test.rb test/services/shop/guest_order_broadcaster_test.rb test/channels/shop/guest_order_channel_test.rb test/integration/shop/api/active_orders_test.rb`

## Local GREEN

- JS sheet: 23/0 PASS · poll: 6/0 PASS
- rails zone: 35/0 PASS
- Entire: `01M1XDGFW23WY77ZRW73D5KGT4` на `04bd55b7` (ops after GREEN `8cae376d`)

## Local /regress

- `node --test …order_status_sheet… + …active_poll…` → **29/0 PASS**
- `bin/rails test` cascade+notifier+broadcaster+channel+active_orders → **35 runs / 105 assert / 0 fail**
