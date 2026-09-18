# Artifacts — TASK_93 Critical path hardening

**CBR:** #93 · **ТЗ:** [`../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md`](../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md)

Сюда — скрины, JSON, MCP-артефакты по блокам A–L (не в корень репо).

| Файл | Назначение |
|------|------------|
| `GATES.md` | unlazy ledger **активного блока** (= сейчас B) |
| `GATES-block-A.md` | ledger блока A |
| `GATES-block-B.md` | зеркало ledger блока B |
| `GATES-block-C.md` | ledger блока C (параллельный чат; не активный session) |

| Блок | Фокус |
|------|--------|
| A | Деньги ↔ заказ — ledger `GATES-block-A.md` · SPEC в todo (др. чат) |
| B | Checkout identity — **сейчас** · [ТЗ B](../../requirements/customer_tasks/TASK-93-B-Checkout-identity.md) · `GATES.md` · Next: `/spec` |
| C | SMS short link — ledger `GATES-block-C.md` · ждёт свой `/start`→`/spec` |
| D–K | см. карту в зонтике |
| L | Deploy + Point A MCP |
