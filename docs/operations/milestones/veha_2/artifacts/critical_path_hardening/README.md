# Artifacts — TASK_93 Critical path hardening

**CBR:** #93 · **ТЗ:** [`../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md`](../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md)

Сюда — скрины, JSON, MCP-артефакты по блокам A–L (не в корень репо).

| Файл | Назначение |
|------|------------|
| `GATES-block-E.md` | **канон ledger блока E** (этот чат) — `gate-check` / `session/GATES.md` |
| `GATES-block-D.md` | ledger блока D |
| `GATES-block-C.md` | ledger блока C |
| `GATES-block-B.md` | ledger блока B |
| `GATES-block-A.md` | ledger блока A |
| `session/GATES.md` | общий слот — сейчас зеркало **E**; при параллели смотри `GATES-block-*.md` |

| Блок | Фокус |
|------|--------|
| A | Деньги ↔ заказ · `GATES-block-A.md` · SPEC в todo → `/sbr` |
| B | Checkout identity · `GATES-block-B.md` · [ТЗ B](../../requirements/customer_tasks/TASK-93-B-Checkout-identity.md) |
| C | SMS short link · `GATES-block-C.md` |
| D | orders history per_page · `GATES-block-D.md` |
| E | Init idempotency / txn — **сейчас** · `GATES-block-E.md` · Next: `/spec` |
| F–K | см. карту в зонтике |
| L | Deploy + Point A MCP |
