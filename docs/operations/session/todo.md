# todo — Status inside cart sheet

**ТЗ:** [`customer_tasks/Статус заказа внутри шторки корзины не слой поверх.md`](../milestones/veha_2/requirements/customer_tasks/Статус%20заказа%20внутри%20шторки%20корзины%20не%20слой%20поверх.md)  
**Артефакты:** [`artifacts/status_inside_cart_sheet/`](../milestones/veha_2/artifacts/status_inside_cart_sheet/)  
**Фаза:** SPEC `[x]` · RED `[x]` · GREEN `[x]` · REVIEW `[x]` · MCP/deploy `[ ]`

## SPEC

| # | Что | Канон |
|---|-----|--------|
| M1 | Убрать `<OrderStatusSheet />` из `App.svelte` | `[x]` |
| M2 | Вмонтировать в `CartSheet` после gesture-zone | `[x]` |
| M3 | Режим `embedded`: без fixed/z-60 overlay | `[x]` |
| M4 | Accordion / modes / cable / testids | `[x]` |

## Тесты

- Mount acceptance 5/5 PASS
- JS order_status 18 + frequent terminal 4 PASS
