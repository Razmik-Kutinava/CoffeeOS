# todo — block cash on public shop API (SPEC)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| /start: сверка с `1220d3e2` | SPEC готов; код уже в develop | `/sbr` — регрессия + gap-check |

**Задача:** запретить `payment_method: cash` на публичном `POST /shop/api/orders`; cash только через barista POS (`POST /barista/orders`, staff session).

**Контекст:** реализация в `1220d3e2`; Fly v461 MCP — cash 422 PASS.

## SBR

| Фаза | Статус |
|------|--------|
| SPEC | **`[x]`** 2026-08-28 |
| RED | **`[x]`** (в `1220d3e2`: cash 422 + barista cash OK) |
| GREEN | **`[x]`** (в `1220d3e2`) |
| /regress | **`[ ]`** — `/sbr` |
| REVIEW | **`[ ]`** — после green regress |

## Файлы (ожидаемо)

| Путь | Зачем |
|------|--------|
| `app/services/shop/payment_config.rb` | Канон allowed online: `card/sbp/apple_pay/google_pay`; `validate_online_payment_method!`; `CASH_ONLINE_ERROR` |
| `app/services/shop/order_creator.rb` | Вызов validate до create; `payment_flow` без cash→accepted |
| `app/controllers/shop/api/orders_controller.rb` | Явная validate на `create` → 422 гостю |
| `app/controllers/barista/orders_controller.rb` | POS: cash через `OrderCreationService`, staff RBAC — **не трогать** |
| `app/frontend/lib/tbankPayment.js` | UI labels: только card/sbp (defense in depth) |
| `test/integration/shop/api/orders_controller_test.rb` | POST shop cash → 422, Order/Payment не создаются |
| `test/controllers/barista/orders_controller_test.rb` | POST barista cash → accepted, staff flow OK |

**Blast-radius (+соседи):** `test/services/shop/order_creator_test.rb` (unit cash reject); `test/services/shop/payment_config_test.rb` (validate unit).

## Не ломать

- Barista POS: `POST /barista/orders` + `payment_method: cash` → `accepted`, привязка к `CashShift`
- Shop online: card/sbp simulate/pending флоу (`SHOP_SIMULATE_PAYMENT`, T-Bank init/callback)
- Guest checkout: email verify → order create (default `card`, не cash)
- `PaymentConfig.simulate?` default 0 + prod guard — cash block не должен включать simulate на prod

## Проверка

```bash
PARALLEL_WORKERS=0 bin/rails test \
  test/services/shop/payment_config_test.rb \
  test/services/shop/order_creator_test.rb \
  test/integration/shop/api/orders_controller_test.rb \
  test/controllers/barista/orders_controller_test.rb
```
