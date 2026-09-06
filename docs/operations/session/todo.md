# todo — CartSheet: видимая общая сумма («Итого»)

| Поле | Значение |
|------|----------|
| **Источник** | Правка заказчика **5/**: «в корзине нет общей суммы продаж, добавить» |
| **Тип** | Fix / UX · CartSheet (hot-path витрина) |
| **Цель** | В шторке корзины явно видно **Итого N₽**; hidden total видимый + `formatThousands` |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Fly** | MCP после deploy (не Local-only для DoD) |
| **Ветка** | `develop` |

## SBR

- [x] **SPEC**
- [x] **RED** (`0af4825c`)
- [x] **GREEN** (`7d7cfbec`) + bugbot fix thousands (`91daaf19`)
- [x] **/regress** — cart total + b113/gestures/quick_repeat 36/0
- [x] **REVIEW** — bugbot + security · Entire `01M1V145Z4ABQQM5APY2EXEG6N` · push

## Решение

| # | QA | Решение |
|---|-----|---------|
| 5 | Нет общей суммы | `checkoutBar`: **Итого** + сумма; hidden без `sr-only`; `formatThousands` везде |

## Проверка

- `bin/rails test test/integration/shop/cart_checkout_button_total_dynamic_test.rb` (+ b113 / quick_repeat)
