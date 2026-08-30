# todo — shift close: ready refund + preparing carryover

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| GREEN `1f14dc49` | 45/0 local | `/regress` |

**Задача:** при закрытии смены (manager close wizard) — автоматически отменить + вернуть деньги по **ready** (T-Bank через общий refund); **preparing** оставить доступными следующей смене; не блокировать close из‑за незавершённых заказов; баннер на табло + Telegram-алерт при остатке preparing.

**Точка входа:** `Manager::CloseWizardController#update` → новый `Manager::ShiftCloseService` (оркестрация до/после `CashShift#close!`).

## SBR

| Фаза | Статус |
|------|--------|
| SPEC | **`[x]`** |
| RED / GREEN | **`[x]`** RED `c8cd9627` · GREEN `1f14dc49` |
| /sbr verify | **`[x]`** 45/0 |
| /regress | **`[ ]`** |
| REVIEW | **`[ ]`** |
| push | **`[ ]`** |
| deploy | **`[ ]`** |
| Fly MCP | **`[ ]`** |

## Решения SPEC (канон для SBR)

| # | Правило | Реализация |
|---|---------|------------|
| 1 | **ready** на close | cancel + refund (T-Bank если `provider_payment_id`; иначе локальный cancel как у гостя) |
| 2 | **preparing** на close | не cancel/refund; `BoardOrdersQuery.shift_accessible_sql` + OR `status = preparing` на tenant до `issued`/`cancelled` |
| 3 | Close не блокируется заказами | уже так; **оставить** блокеры wizard: pending payments / failed receipts / pending refunds |
| 4 | Refund без дублирования | extract `Payments::TbankOrderRefund` (или аналог) из `GuestOrderCancellationService#refund_succeeded_via_tbank!`; гость и shift-close вызывают общий метод |
| 5 | Системная отмена ready | `cancel_reason` «Смена закрыта, заказ не забран», `OrderStatusLog.source` = `system`, audit отдельный action |
| 6 | Ошибка T-Bank на ready | **не закрывать смену**, flash с `order_number`; успешные ready до ошибки — откат транзакции (all-or-nothing на фазе ready) |
| 7 | Carryover на табло | preparing из закрытых смен в `board_scope` / слотах новой смены + персистентный баннер (turbo target в layout) |
| 8 | Telegram менеджеру | reuse `TelegramAlertJob` / `AlertService.critical` (не `@code_black_support_bot` — это гостевой deep link) |
| 9 | Barista actions | `OrdersController` show/update/cancel: разрешить carryover-preparing при **открытой** новой смене (через расширенный `shift_accessible_scope`) |

## Файлы (ожидаемо)

| Путь | Зачем |
|------|--------|
| `app/services/manager/shift_close_service.rb` | **новый** — ready cancel/refund, подсчёт preparing, `close!`, broadcast + Telegram |
| `app/services/payments/tbank_order_refund.rb` | **новый** — общий T-Bank cancel + Refund record (extract из guest service) |
| `app/services/shop/guest_order_cancellation_service.rb` | делегировать refund в extract, не дублировать |
| `app/controllers/manager/close_wizard_controller.rb` | вызов `ShiftCloseService` вместо прямого `@shift.close!` |
| `app/services/barista/board_orders_query.rb` | расширить `shift_accessible_sql` для preparing carryover |
| `app/services/barista/order_board_broadcaster.rb` | broadcast carryover-баннера / badge (новый target) |
| `app/views/barista/shared/_layout.html.erb` | DOM target для персистентного баннера незавершённых preparing |

**Blast-radius (hot-path соседи):**

| Путь | Почему |
|------|--------|
| `app/controllers/barista/orders_controller.rb` | show/update/cancel должны видеть carryover-preparing в новой смене |
| `app/services/barista/operating_hours_board.rb` | контекст `@board_hours` для SSR баннера при загрузке табло |
| `test/services/shop/guest_order_cancellation_service_test.rb` | регрессия после extract refund |

**Тесты (новые/расширить):**

- `test/services/manager/shift_close_service_test.rb` (новый)
- `test/services/barista/board_orders_query_test.rb`
- `test/services/barista/order_board_broadcaster_test.rb`
- `test/integration/manager/shift_close_orders_test.rb` (новый, wizard POST)

## Не ломать

- Гостевая отмена + T-Bank refund (`GuestOrderCancellationService`, shop API)
- T-Bank callback / `Payments::TbankAdapter` (не менять контракт cancel)
- Табло FIFO слотов (`BoardOrdersQuery.for_slots`, MAX_SLOTS=6)
- Витринные mobile-заказы после `opened_at` текущей смены
- Wizard-блокеры: pending payments / failed fiscal / pending refunds (не заказы)
- POS `#create` только при открытой смене

## Проверка

```bash
ruby bin/rails test test/services/manager/shift_close_service_test.rb test/services/shop/guest_order_cancellation_service_test.rb test/services/barista/board_orders_query_test.rb test/services/barista/order_board_broadcaster_test.rb test/integration/manager/shift_close_orders_test.rb test/controllers/barista/orders_controller_test.rb
ruby bin/rails test test/integration/manager_* test/integration/block_g_cash_shift_test.rb
```
