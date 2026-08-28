# todo — block cash on public shop API (regress done)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| `/regress` shop+payment 113/0 | local PASS | `/review` |

**Задача:** запретить `payment_method: cash` на публичном `POST /shop/api/orders`; cash только через barista POS.

**Контекст:** GREEN `1220d3e2`; local regress 2026-08-28 **113 runs / 417 assertions / 0 failures / 2 skips**.

## SBR

| Фаза | Статус |
|------|--------|
| SPEC | **`[x]`** |
| RED / GREEN | **`[x]`** `1220d3e2` |
| /sbr verify | **`[x]`** 46/0 |
| /regress | **`[x]`** 113/0 local 2026-08-28 |
| REVIEW | **`[ ]`** |

## Файлы (ожидаемо)

| Путь | Зачем |
|------|--------|
| `app/services/shop/payment_config.rb` | validate online methods |
| `app/services/shop/order_creator.rb` | no cash→accepted |
| `app/controllers/shop/api/orders_controller.rb` | 422 on cash |
| `app/controllers/barista/orders_controller.rb` | POS cash OK |
| `app/frontend/lib/tbankPayment.js` | UI card/sbp only |
| `test/integration/shop/api/orders_controller_test.rb` | shop cash 422 |
| `test/controllers/barista/orders_controller_test.rb` | barista cash OK |

## Не ломать

- Barista POS cash + `CashShift`
- Shop card/sbp + T-Bank callback
- Guest checkout default `card`

## Проверка

**SBR (todo):**
```bash
PARALLEL_WORKERS=0 bin/rails test \
  test/services/shop/payment_config_test.rb \
  test/services/shop/order_creator_test.rb \
  test/integration/shop/api/orders_controller_test.rb \
  test/controllers/barista/orders_controller_test.rb
```
→ 46/0 (2026-08-28)

**Regress зона shop checkout + §2.3 + T-Bank:**
```bash
PARALLEL_WORKERS=0 bin/rails test \
  test/services/shop/payment_config_test.rb \
  test/services/shop/order_creator_test.rb \
  test/integration/shop/api/orders_controller_test.rb \
  test/controllers/barista/orders_controller_test.rb \
  test/integration/shop/api/qa_section_2_3_payment_cart_test.rb \
  test/integration/shop/api/qa_section_2_3_stage5_e2e_test.rb \
  test/integration/shop/api/mvp_flow_test.rb \
  test/integration/shop/checkout_acceptance_cbr_test.rb \
  test/integration/shop/block_e_shop_flow_test.rb \
  test/controllers/callbacks/tbank_controller_test.rb \
  test/services/payments/tbank_adapter_test.rb
```
→ **113 runs, 417 assertions, 0 failures, 2 skips** (2026-08-28)
