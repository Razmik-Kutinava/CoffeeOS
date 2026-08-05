# todo — #42 Stuck orders sheet blocks payment (2026-08-05)

**ТЗ:** [`customer_tasks/Зависшие заказы…`](../milestones/veha_2/requirements/customer_tasks/Зависшие%20заказы%20в%20статусной%20шторке%20PWA%20блокируют%20оплату.md)  
**Артефакты:** [`artifacts/stuck_orders_status_sheet_blocks_payment/`](../milestones/veha_2/artifacts/stuck_orders_status_sheet_blocks_payment/)

## SPEC

| # | Шаг | Статус |
|---|-----|--------|
| 1 | TTL 24h на `GET orders/active` (June stuck out) | `[x]` |
| 2 | Peek max-height `min(22vh, 8.5rem)` | `[x]` |
| 3 | Тесты active + mount | `[x]` |
| 4 | FAQ payment processing/succeeded в ТЗ | `[x]` |
| 5 | Push/deploy/MCP | `[ ]` |
| 6 | Backlog: SM filter NULL-shift; payment row sync | backlog |

## Почему табло пусто

Board = только текущая смена. `#202606-*` старше `shift.opened_at` → не на табло (ожидаемо).
