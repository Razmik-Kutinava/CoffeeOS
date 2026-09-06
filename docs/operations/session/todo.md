# todo — CartSheet: видимая общая сумма («Итого»)

| Поле | Значение |
|------|----------|
| **Источник** | Правка заказчика **5/**: «в корзине нет общей суммы продаж, добавить» |
| **Тип** | Fix / UX · CartSheet (hot-path витрина) |
| **Цель** | В шторке корзины явно видно **Итого N₽** (не только `+N₽` на кнопке); в hidden — сумма не `sr-only` |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Fly** | MCP после REVIEW/deploy (не Local-only для закрытия DoD) |
| **Ветка** | `develop` |
| **Запрет** | менять расчёт `cartTotal`; ломать кнопку `+N₽`; второй fixed-слой; gem’ы оплаты |

## SBR

- [x] **SPEC** — пути + Не ломать + Проверка
- [ ] **RED** — тест: видимое «Итого» + hidden total без `sr-only`
- [ ] **GREEN** — UI в `CartSheet` + регрессия зоны
- [ ] **/regress** — команды из «Проверка»
- [ ] **REVIEW** — bugbot + security-review + Entire + push

## Решение

| # | QA | Решение |
|---|-----|---------|
| 5 | В корзине нет общей суммы | В `checkoutBar`: слева **Итого** + сумма (`shop-cart-order-total`), справа кнопка `+N₽`. Hidden: `shop-cart-hidden-total` сделать видимым (убрать `sr-only`). Кнопку и `formatCartButtonTotal` не трогать. |

## Файлы (ожидаемо)

1. `app/frontend/components/CartSheet.svelte` — «Итого» в checkoutBar; visible hidden-total
2. `test/integration/shop/cart_checkout_button_total_dynamic_test.rb` — assert Итого + hidden без sr-only
3. `test/integration/shop/b113_s2a_cart_sheet_acceptance_test.rb` — peek/hidden total остаются

## Не ломать

- Кнопка `shop-cart-sheet-checkout` = `+N₽` (`formatCartButtonTotal`)
- Жесты peek/hidden/expanded + pay-stack
- Расчёт `cartTotal` / API cart
- Repeat section / OrderStatusSheet embedded

## Проверка

- `bin/rails test test/integration/shop/cart_checkout_button_total_dynamic_test.rb test/integration/shop/b113_s2a_cart_sheet_acceptance_test.rb test/integration/shop/b113_s2_layout_gestures_test.rb test/integration/shop/quick_repeat_sheet_layout_canon_test.rb`
