# todo — TASK_121 Subtask 8: Повтор заказов других и закрытых точек (очередь, шаг 16)

| Поле | Значение |
|------|----------|
| **Очередь** | [PUSH_SMS_QUEUE](../milestones/veha_2/requirements/PUSH_SMS_QUEUE.md) · шаг **16** `done` · зависимости 12 / 13 = done |
| **Основание** | [TASK-121-…](../milestones/veha_2/requirements/customer_tasks/TASK-121-Повтор-заказа-из-истории-с-проверкой-цен-в-текущей-точке.md) · секция Subtask 8 · CBR #121 · Google Doc v3 |
| **Статус** | **done** 2026-11-02 · CI green [41456144439](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/41456144439) · миграции нет · не задеплоено (🚀 7) |

## SBR

- [x] intake · SPEC · RED `51c50d5e` · GREEN `70da0ca3` · Entire `01M6E6SK26KVPBMSJWMAJXCFQ4`
- [x] `/review` — local PASS · crit-audit CLEAN · COMPONENT_MAP: да · push `38d277e2` · **CI green** [41456144439](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/41456144439) + Semgrep/CodeQL

## Итог

`#repeat_preview` читает заказ через `CodeBlackCrossPointOrders` (как `#show`); цены — меню текущей точки; вне сети чужая точка → 404.
