# todo — TASK_84-RECEIPT-DISPLAY-EXT (stub)

| Поле | Значение |
|------|----------|
| **ID** | TASK_84-RECEIPT-DISPLAY-EXT · #84 |
| **Статус** | REVIEW · CI green · **G5 Fly unmet** (после deploy) |
| **GREEN** | `4e84a4b4` · Entire `01M31GK06473NABJMKATBKCJD0` |
| **CI** | [`35579839261`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/35579839261) |
| **Полный SPEC** | [`archive/todo-task84-receipt-2026-09.md`](archive/todo-task84-receipt-2026-09.md) |

## next_step

1. deploy апрув → Fly
2. G5 Point A: expand → `.aoa__receipt` runtime text

## Проверка (после deploy)

```bash
node --test test/javascript/active_orders_accordion_test.mjs
```
