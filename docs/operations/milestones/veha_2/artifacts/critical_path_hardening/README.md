# Artifacts — TASK_93 Critical path hardening

**CBR:** #93 · **ТЗ:** [`../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md`](../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md)

Сюда — скрины, JSON, MCP-артефакты по блокам A–L (не в корень репо).

| Файл | Назначение |
|------|------------|
| `GATES.md` | unlazy ledger **блока B** (активный) |
| `GATES-block-A.md` | unlazy ledger блока A (отложен) |

| Блок | Фокус |
|------|--------|
| A | Деньги ↔ заказ (склад + webhook) — intake, ждёт `/spec` · ledger `GATES-block-A.md` |
| B | Checkout identity (phone vs email) — **сейчас** · [ТЗ B](../../requirements/customer_tasks/TASK-93-B-Checkout-identity.md) · ledger `GATES.md` |
| C–K | см. карту в зонтике |
| L | Deploy + Point A MCP |
