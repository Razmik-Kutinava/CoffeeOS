# todo — barista: заказы только текущей смены (show/update/cancel)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| /review + CI green | GREEN `af05031b` · push `81ed6782` | deploy апрув |

**Задача:** `OrdersController#show`, `#update_status`, `#cancel` не должны отдавать/менять заказы вне текущей открытой смены (и витрины mobile с `opened_at` смены — канон `BoardOrdersQuery`).

## SBR

| Фаза | Статус |
|------|--------|
| SPEC | **`[x]`** |
| RED / GREEN | **`[x]`** `af05031b` (сделано до формального SBR) |
| /sbr verify | **`[x]`** 58 runs, 370 assertions, 0 failures |
| /regress | **`[x]`** 107 runs, 485 assertions, 0 failures |
| REVIEW | **`[x]`** local 58/0 · bugbot 1 medium (history/show — out of scope) · security OK · push CI |
| push | **`[x]`** CI #33185812722 green |
| deploy | **`[ ]`** |
| Fly MCP | **`[ ]`** skip (не shop/pay hot-path) |

## SPEC

### Проблема

`Order.for_current_tenant.find(params[:id])` в трёх экшенах даёт доступ ко всей истории точки — бариста может открыть/изменить заказ закрытой смены по прямому URL.

### Решение

1. Общий scope **`BoardOrdersQuery.shift_accessible_scope`** (уже на табло):
   - `cash_shift_id = current_shift.id`
   - **ИЛИ** витрина: `cash_shift_id IS NULL` + `source = mobile` + `created_at >= shift.opened_at`
2. `show` / `update_status` / `cancel` → `shift_accessible_orders.find(params[:id])`
3. Без открытой смены → **403 JSON** / redirect HTML+turbo («Смена не открыта…»), не `where(cash_shift_id: nil)`.

### Не в scope

- `history` — отдельный экран архива (остаётся `for_current_tenant` + фильтры)
- Заказы **прошлой закрытой смены** на стыке смен — **не доступны** (согласовано с B1.11 / пустое табло)

## Файлы (ожидаемо)

| Путь | Зачем |
|------|--------|
| `app/controllers/barista/orders_controller.rb` | `show` / `update_status` / `cancel` + `shift_accessible_orders`, guard без смены |
| `app/services/barista/board_orders_query.rb` | `shift_accessible_scope` — единый SQL с табло |
| `test/controllers/barista/orders_controller_test.rb` | смена OK · чужая смена 404 · витрина OK · без смены 403 |
| `app/controllers/barista/base_controller.rb` | *(blast)* `current_shift` — источник открытой смены |
| `test/integration/block_g_cash_shift_test.rb` | *(blast)* guard «смена закрыта» на update_status |
| `test/integration/barista_tablet_regression_test.rb` | *(blast)* tenant isolation + tablet flows |

## Не ломать

- Табло бариста (`BoardOrdersQuery.board_scope`) — тот же SQL, что и доступ по id
- Витринные mobile-заказы (`cash_shift_id NULL`) после `opened_at` смены — видны и на табло, и в API
- POS create (`#create`) — по-прежнему требует открытую смену, пишет `cash_shift_id`
- Shop card/sbp + T-Bank callback — не трогаем
- `history` — полная история точки для отчёта бариста

## Проверка

```bash
ruby bin/rails test test/controllers/barista/orders_controller_test.rb test/services/barista/board_orders_query_test.rb
ruby bin/rails test test/integration/block_g_cash_shift_test.rb test/integration/barista_tablet_regression_test.rb test/integration/auth/barista_rbac_test.rb
```
