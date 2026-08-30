# Phase 5 — ABAC-lite

**Статус:** in_progress 2026-08-30 · апрув Phase 4 ✅  
**Предусловие:** Phase 4 DoD закрыт ([phase_4_rbac_dod/](../phase_4_rbac_dod/))

---

## Deliverables

| # | Артефакт | Путь |
|---|----------|------|
| 1 | Каталог атрибутов | [ABAC_ATTRIBUTES.md](ABAC_ATTRIBUTES.md) |
| 2 | Каталог правил (58) | [ABAC_POLICIES.md](ABAC_POLICIES.md) |
| 3 | PolicyContext | `app/policies/policy_context.rb` |
| 4 | Policies refactor | Order, CashShift, User, StockMovement |
| 5 | ABAC tests | `test/policies/*_abac_test.rb` |

---

## Scope IN (Phase 5)

- ≥50 правил в документе (факт: **58**)
- PolicyContext + pundit_user в barista/manager/prep base
- shift_open / in_shift enforce на barista order mutations
- ≥15 ABAC unit tests

## Scope OUT

- Kiosk/TV implementation (ABAC-056…058 backlog)
- Blog (ABAC-007)
- Full enforce всех 58 правил (Phase 5b)
- Fly MCP / deploy
- DB migrations

---

## DoD Phase 5

- [x] ≥50 rules in ABAC_POLICIES.md
- [x] PolicyContext exists and used in ≥3 policies
- [x] shift_open enforced on barista order mutations
- [x] ≥15 ABAC tests (target)
- [x] No kiosk/TV code
- [ ] commit + ops (+ push if green) — agent step

---

## Phase 5b backlog

Правила с `Impl=N` или `Partial` в [ABAC_POLICIES.md](ABAC_POLICIES.md) — перенос без изменения RBAC.

**Next:** owner approval → push → CI → Phase 5b planning.
