# todo — block cash on public shop API (SBR verify)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| `/sbr` regress 46/0 local | GREEN в `1220d3e2` подтверждён | `/regress` шире shop checkout |

**Задача:** запретить `payment_method: cash` на публичном `POST /shop/api/orders`; cash только через barista POS.

**Контекст:** реализация `1220d3e2`; local verify 2026-08-28 **46 runs / 146 assertions / 0 failures**.

## SBR

| Фаза | Статус |
|------|--------|
| SPEC | **`[x]`** 2026-08-28 |
| RED | **`[x]`** `1220d3e2` |
| GREEN | **`[x]`** `1220d3e2` |
| /sbr verify | **`[x]`** 46/0 local 2026-08-28 |
| /regress | **`[ ]`** — шире checkout zone |
| REVIEW | **`[ ]`** |

## Файлы (ожидаемо)

| Путь | Зачем |
|------|--------|
| `app/services/shop/payment_config.rb` | Канон allowed online; `validate_online_payment_method!` |
| `app/services/shop/order_creator.rb` | Validate до create; `payment_flow` без cash→accepted |
| `app/controllers/shop/api/orders_controller.rb` | Validate на `create` → 422 |
| `app/controllers/barista/orders_controller.rb` | POS cash — без изменений |
| `app/frontend/lib/tbankPayment.js` | UI: card/sbp only |
| `test/integration/shop/api/orders_controller_test.rb` | shop cash → 422 |
| `test/controllers/barista/orders_controller_test.rb` | barista cash → OK |

## Не ломать

- Barista POS cash + `CashShift`
- Shop card/sbp simulate/pending + T-Bank callback
- Guest checkout default `card`
- `PaymentConfig.simulate?` default 0 + prod guard

## Проверка

```bash
PARALLEL_WORKERS=0 bin/rails test \
  test/services/shop/payment_config_test.rb \
  test/services/shop/order_creator_test.rb \
  test/integration/shop/api/orders_controller_test.rb \
  test/controllers/barista/orders_controller_test.rb
```

**Результат 2026-08-28:** 46 runs, 146 assertions, 0 failures, 0 errors, 0 skips
