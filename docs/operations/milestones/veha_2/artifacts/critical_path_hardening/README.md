# Artifacts — TASK_93 Critical path hardening

**CBR:** #93 · **ТЗ:** [`../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md`](../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md)

Сюда — скрины, JSON, MCP-артефакты по блокам A–L (не в корень репо).

| Файл | Назначение |
|------|------------|
| `GATES-block-B.md` | **канон ledger блока B** (этот чат) — `gate-check` сюда |
| `GATES-block-A.md` | ledger блока A |
| `GATES-block-C.md` | ledger блока C |
| `GATES-block-D.md` | ledger блока D |
| `session/GATES.md` | общий слот — **не** полагаться при параллельных блоках |

| Блок | Фокус |
|------|--------|
| A | Деньги ↔ заказ · `GATES-block-A.md` |
| B | Checkout identity — **сейчас** · [ТЗ B](../../requirements/customer_tasks/TASK-93-B-Checkout-identity.md) · `GATES-block-B.md` · Next: `/spec` |
| C | SMS short link · `GATES-block-C.md` |
| D | orders history per_page · `GATES-block-D.md` |
| E–K | см. карту в зонтике |
| L | Deploy + Point A MCP |
