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

- [x] **SPEC**
- [ ] **RED**
- [ ] **GREEN**
- [ ] **/regress**
- [ ] **REVIEW**

## Решение (slice)

| # | Решение |
|---|---------|
| 1 | **Шторка:** `ready` = terminal для виджета (#35/#82). `applyCableEvent` снимает карточку на `ready`; `/orders/active` **без** `ready` (сейчас accepted\|preparing\|ready — поэтому залипает). |
| 2 | После hide-on-ready — refresh frequent / «повторить» (уже в terminal-path); не возвращать пустой +0₽ без repeats (#42/#43 риск). |
| 3 | **SMS-каскад:** цепочка уже есть (`GuestOrderBroadcaster` → `OrderReadyCascadeJob` @15s → presence → `OrderReadyPaidNotifier`). Починить регрессию: ложный `online` / не сброс presence / enqueue; логи — `order_notification_logs` (не `notification_histories`). |
| 4 | Триггер баристы = `PATCH update_status` → `ready` (не `POST …/ready` из ТЗ). RSpec/WebMock из Google Doc — **не** внедрять; канон Minitest + существующие JS tests. |
| 5 | **Вне slice:** смена SMS-шаблона на URL `codeblack.xyz/o/{hash}` (сейчас `#order_number` ≤70); Apple Wallet/WebPush greenfield; RSpec-пути из дока. |

## Файлы (ожидаемо)

- `app/frontend/lib/orderStatusSheet.js` — `ready` в terminal; Cable снимает карточку с гл. экрана
- `app/controllers/shop/api/orders_controller.rb` — `#active` только `accepted`/`preparing` (без `ready`)
- `app/jobs/shop/order_ready_cascade_job.rb` — presence → SMS или skip + лог
- `app/channels/shop/guest_order_channel.rb` — set/clear `order:{id}:online` (липкий online блокирует SMS)
- `app/services/shop/order_ready_paid_notifier.rb` — SMS.ru + `order_notification_logs`
- `app/services/shop/guest_order_broadcaster.rb` — WS/push + enqueue cascade на `ready`

### Blast-radius (+3)

- `app/frontend/components/OrderStatusSheet.svelte` — UI/poll/`shouldShowStatusSheetUi` (не ломать dismiss/routes)
- `app/services/shop/order_ready_presence.rb` — ключ presence (Rails.cache, не Redis)
- `app/services/shop/sms_ru_client.rb` — HTTP sms.ru / ValidationError ≤70

## Не ломать

- Оплата One-Click / СБП / webhook → `accepted`
- «Повторить» / frequent после выдачи (hide-on-ready не должен гасить repeats навсегда)
- Табло баристы `update_status` + board broadcast
- Peek CartSheet / status-inside-sheet (#35 mount) на `accepted`/`preparing`

## Проверка

- `node --test test/javascript/order_status_sheet_test.mjs test/javascript/order_status_active_poll_test.mjs`
- `bin/rails test test/jobs/shop/order_ready_cascade_job_test.rb test/services/shop/order_ready_paid_notifier_test.rb test/services/shop/guest_order_broadcaster_test.rb test/channels/shop/guest_order_channel_test.rb test/integration/shop/api/active_orders_test.rb`
