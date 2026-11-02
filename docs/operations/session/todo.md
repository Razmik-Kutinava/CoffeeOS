# todo — TASK_118: SMS «Заказ готов» → история заказов CODE:BLACK (очередь, шаг 15)

| Поле | Значение |
|------|----------|
| **Очередь** | [PUSH_SMS_QUEUE](../milestones/veha_2/requirements/PUSH_SMS_QUEUE.md) · шаг **15** `done` · зависимости 2 / 4 / 5 / 13 / 14 / 0.4 = done |
| **Основание** | [TASK-118-…](../milestones/veha_2/requirements/customer_tasks/TASK-118-SMS-Заказ-готов-история-заказов-CODE-BLACK.md) · CBR #118 · Google Doc v4 |
| **Статус** | **done** 2026-11-02 · CI green [41453248573](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/41453248573) · миграции нет · не задеплоено (🚀 7) |

## SBR

- [x] intake · SPEC · RED `7be416af` · GREEN `5422913e` · Entire `01M6E6SK26KVPBMSJWMAJXCFQ4`
- [x] `/review` — local PASS · crit-audit CLEAN · COMPONENT_MAP: нет · push `3e0e1749` · **CI green** [41453248573](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/41453248573) + Semgrep/CodeQL

## Итог

SMS `/o/:hash` → `#/profile?order=` + `sms_entry` pin; expired/invalid → HTML без bind; TASK_117 confirm сохранён; Subtask 9 — шаг 0.3.
