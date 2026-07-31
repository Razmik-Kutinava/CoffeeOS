# todo — Status inside cart sheet

**ТЗ:** [`customer_tasks/Статус заказа внутри шторки корзины не слой поверх.md`](../milestones/veha_2/requirements/customer_tasks/Статус%20заказа%20внутри%20шторки%20корзины%20не%20слой%20поверх.md)  
**Артефакты:** [`artifacts/status_inside_cart_sheet/`](../milestones/veha_2/artifacts/status_inside_cart_sheet/)  
**Фаза:** SPEC `[x]` · RED `[ ]` · GREEN `[ ]` · REVIEW `[ ]`

## SPEC

| # | Что | Канон |
|---|-----|--------|
| M1 | Убрать `<OrderStatusSheet />` из `App.svelte` | не sibling overlay |
| M2 | Вмонтировать в `CartSheet` после gesture-zone | DOM-потомок `shop-cart-sheet` |
| M3 | Режим `embedded`: без `position:fixed` / без отдельного z-60 overlay | relative flow внутри шторки |
| M4 | Сохранить accordion / modes / cable reconnect / testids | #35/#36 не ломать по смыслу |

## RED

- [ ] Mount test: CartSheet embeds OrderStatusSheet; App не маунтит
- [ ] Embedded CSS: нет fixed overlay в embedded-режиме

## GREEN

- [ ] Реализация M1–M4
- [ ] Регрессия mount + order_status JS
