# todo — barista: заказы только текущей смены (show/update/cancel)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| deploy v465 + MCP PASS | GREEN `af05031b` на Fly | — закрыто |

**Задача:** `OrdersController#show`, `#update_status`, `#cancel` не должны отдавать/менять заказы вне текущей открытой смены (и витрины mobile с `opened_at` смены — канон `BoardOrdersQuery`).

## SBR

| Фаза | Статус |
|------|--------|
| SPEC | **`[x]`** |
| RED / GREEN | **`[x]`** `af05031b` |
| /sbr verify | **`[x]`** 58/0 |
| /regress | **`[x]`** 107/0 |
| REVIEW | **`[x]`** bugbot + security · CI #33185812722 green |
| push | **`[x]`** |
| deploy | **`[x]`** v465 · `deployment-01M167Z816GPZYVX109PBWXQQD` |
| Fly MCP | **`[x]`** P0–P7 PASS · Sentry 24h clean |

## Не ломать

- Табло бариста (`BoardOrdersQuery.board_scope`)
- Витринные mobile-заказы после `opened_at`
- POS `#create` + CashShift
- Shop card/sbp + T-Bank callback

## Проверка

```bash
ruby bin/rails test test/controllers/barista/orders_controller_test.rb test/services/barista/board_orders_query_test.rb
ruby bin/acceptance/fly_v461_mcp_acceptance.rb
```
