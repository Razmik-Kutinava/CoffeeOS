# todo — SMS «Готов!» всегда + карточка на ready

| Поле | Значение |
|------|----------|
| **Статус** | local-done · GREEN · push/deploy нет (запрет владельца) |
| **Основание** | заказчик апрувил · владелец: сделать целиком |

## Файлы (ожидаемо)

- `app/jobs/shop/order_ready_cascade_job.rb` — убрать пропуск SMS при presence online
- `app/services/shop/guest_order_broadcaster.rb` — слать каскад сразу, без паузы ~20с
- `app/services/shop/order_ready_paid_notifier.rb` — текст/повтор/нет телефона уже здесь, не менять контракт
- `app/services/shop/order_ready_sms_link.rb` — текст и ссылку не менять
- `app/controllers/shop/api/orders_controller.rb` — `ready` остаётся в `/orders/active` (poll не снимает карточку)
- `app/frontend/lib/orderStatusSheet.js` — `ready` не terminal; крестик только на ready
- `app/frontend/components/ActiveOrdersAccordion.svelte` + `OrderStatusSheet.svelte` — X только на ready, закрытие гостем

Соседи (не ломать): `order_ready_presence.rb` и канал presence остаются; пуш / FCM / Wallet / препромпт / плашка установки не выключать. Табло бариста не трогать. `CustomerFrequentProductsService` — ready по-прежнему не гасит «повторить».

## Не ломать

- Повтор того же SMS не уходит (`already sent`). Нет телефона — SMS нет. Не mobile — каскад не ставится.
- Текст `CODE:BLACK. Готов! {host}/o/{hash}` без смены.
- `issued` / `closed` / `cancelled` снимают карточку. На accepted/preparing крестика нет, карточка сама не пропадает.
- Push (`OrderStatusPushNotifier` / `ReadyPushJob`), Wallet, препромпт, плашка установки живы.
- Табло бариста: нет «Выдан», последний жест «готово».

## Проверка

- `bin/rails test test/jobs/shop/order_ready_cascade_job_test.rb test/services/shop/guest_order_broadcaster_test.rb test/services/shop/order_ready_paid_notifier_test.rb test/services/shop/order_ready_presence_test.rb test/integration/shop/api/active_orders_test.rb test/channels/shop/guest_order_channel_test.rb`
- `node --test test/javascript/order_status_sheet_test.mjs test/javascript/frequent_refresh_on_terminal_test.mjs test/javascript/active_orders_accordion_test.mjs test/javascript/order_status_notify_actions_test.mjs test/javascript/order_action_buttons_cable_test.mjs`

## SBR

- [x] RED — тесты нового контракта падают (`4978600e`)
- [x] GREEN — SMS сразу на ready; карточка с полной полоской «Готов» и X только там
- [x] REVIEW — регрессия зоны, crit-audit CLEAN. Push нет (явный запрет). Deploy нет. Entire id нет.
